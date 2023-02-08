require 'twitter_with_auto_pagination'

class ApiClient
  def initialize(client, user = nil)
    @client = client
    @user = user
  end

  def create_direct_message(recipient_id, message, async: false)
    if async
      # TODO Remove later
      raise NotImplementedError
    else
      twitter.create_direct_message_event(recipient_id, message)
      DirectMessageSendCounter.increment(recipient_id) if recipient_id != User::EGOTTER_UID
      CreateDirectMessageEventLogsWorker.perform_async(@user&.uid, recipient_id, nil, Time.zone.now)
      CreateDirectMessageSendLogWorker.perform_async(sender_id: @user&.uid, recipient_id: recipient_id, message: message)
      true
    end
  rescue => e
    CreateDirectMessageErrorLogWorker.perform_async(sender_id: @user&.uid, recipient_id: recipient_id, error_class: e.class, error_message: e.message, properties: {args: [recipient_id, message]}, created_at: Time.zone.now)
    update_blocker_status(e)

    if e.class == ApiClient::RetryExhausted
      Airbag.warn "Sending DM failed method=#{__method__} user_id=#{@user&.id} recipient_id=#{recipient_id} message=#{message}"
    elsif DirectMessageStatus.enhance_your_calm?(e)
      SendEnhanceYourCalmMessageToSlackWorker.perform_async([recipient_id, message])
    end

    raise
  end

  def create_direct_message_event(event:)
    resp = twitter.create_direct_message_event(event: event).to_h
    dm = DirectMessageWrapper.from_event(resp)
    DirectMessageSendCounter.increment(dm.recipient_id) if dm.recipient_id != User::EGOTTER_UID
    CreateDirectMessageEventLogsWorker.perform_async(dm.sender_id, dm.recipient_id, nil, Time.zone.now)
    CreateDirectMessageSendLogWorker.perform_async(sender_id: dm.sender_id, recipient_id: dm.recipient_id, message: dm.text)
    dm
  rescue => e
    failed_dm = DirectMessageWrapper.from_event(event)
    CreateDirectMessageErrorLogWorker.perform_async(sender_id: @user&.uid, recipient_id: failed_dm.recipient_id, error_class: e.class, error_message: e.message, properties: {args: {event: event}}, created_at: Time.zone.now)
    update_blocker_status(e)

    if e.class == ApiClient::RetryExhausted
      if failed_dm.recipient_id != User::EGOTTER_UID && @user
        CreateDirectMessageEventWorker.perform_in(5.seconds, @user.id, event)
        raise MessageWillBeResent.new("user_id=#{@user.id} recipient_id=#{failed_dm.recipient_id} message=#{failed_dm.text.to_s.truncate(50).gsub("\n", ' ')}")
      end
    elsif DirectMessageStatus.enhance_your_calm?(e)
      SendEnhanceYourCalmMessageToSlackWorker.perform_async(event: event)
    end

    raise
  end

  # Shorthand for #create_direct_message_event
  def send_report(uid, message, buttons = [])
    if buttons.blank?
      event = DirectMessageEvent.build(uid, message)
    else
      event = DirectMessageEvent.build_with_replies(uid, message, buttons)
    end
    create_direct_message_event(event: event)
  end

  def send_report_message(uid, message, quick_reply)
    raise 'Only egotter can send reports' if @user.uid != User::EGOTTER_UID
    event = DirectMessageEvent.build_with_replies(uid, message, quick_reply)
    request = CreateDirectMessageRequest.create!(sender_id: User::EGOTTER_UID, recipient_id: uid, properties: {event: event})
    CreateReportMessageWorker.perform_async(request.id)
  end

  def can_send_dm?(uid)
    twitter.friendship(@user.uid, uid).source.can_dm?
  end

  def permission_level
    TwitterRequest.new(__method__).perform do
      PermissionLevelClient.new(twitter).permission_level
    end
  rescue => e
    update_authorization_status(e)
    update_lock_status(e)
    raise
  end

  [:verify_credentials, :user, :users, :user_timeline, :mentions_timeline, :search,
   :favorites, :friendship?].each do |method|
    define_method(method) do |*args, **kwargs, &blk|
      call_api(method, *args, **kwargs, &blk)
    end
  end

  # TODO Implement all methods and stop using #method_missing
  def method_missing(method, *args, **kwargs, &block)
    if @client.respond_to?(method)
      Airbag.info "ApiClient#method_missing: #{method} is not implemented"
      call_api(method, *args, **kwargs, &block)
    else
      super
    end
  end

  def call_api(method, *args, **kwargs, &block)
    TwitterRequest.new(method).perform do
      # TODO This conditional branch may not be needed on Ruby30
      if kwargs.empty?
        @client.send(method, *args, &block)
      else
        @client.send(method, *args, **kwargs, &block)
      end
    end
  rescue => e
    update_authorization_status(e)
    update_lock_status(e)
    create_not_found_user(e, *args) if method == :user
    create_forbidden_user(e, *args) if method == :user
    raise
  ensure
    # CreateTwitterApiLogWorker.perform_async(name: "ApiClient##{method}")
  end

  def update_blocker_status(e)
    if DirectMessageStatus.you_have_blocked?(e) && @user
      CreateViolationEventWorker.perform_async(@user.id, 'Blocking egotter')
    end
  end

  def update_authorization_status(e)
    if TwitterApiStatus.unauthorized?(e) && @user
      UpdateUserAttrsWorker.perform_async(@user.id)
    end
  end

  def update_lock_status(e)
    if TwitterApiStatus.temporarily_locked?(e) && @user
      UpdateLockedWorker.perform_async(@user.id)
    end
  end

  def create_not_found_user(e, *args)
    if TwitterApiStatus.not_found?(e) && args.length >= 1 && args[0].is_a?(String)
      CreateNotFoundUserWorker.perform_async(args[0], location: (caller[2][/`([^']*)'/, 1] rescue ''))
    end
  end

  def create_forbidden_user(e, *args)
    if TwitterApiStatus.suspended?(e) && args.length >= 1 && args[0].is_a?(String)
      CreateForbiddenUserWorker.perform_async(args[0], location: (caller[2][/`([^']*)'/, 1] rescue ''))
    end
  end

  def app_context?
    @user.nil?
  end

  def owner
    @user
  end

  def twitter
    TwitterClient.new(self, @client.twitter)
  end

  class << self
    def config(options = {})
      {
          consumer_key: ENV['TWITTER_CONSUMER_KEY'],
          consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
          access_token: nil,
          access_token_secret: nil,
          timeouts: {connect: 1, read: 2, write: 4}
      }.merge(options)
    end

    def instance(options = {})
      if options.blank?
        client = TwitterWithAutoPagination::Client.new
      else
        if options[:cache_store] == :null_store
          options[:cache_store] = ActiveSupport::Cache::NullStore.new
        else
          options[:cache_store] = ApiClientCacheStore.instance
        end
        client = TwitterWithAutoPagination::Client.new(config(options))
      end

      new(client, options[:user])
    end
  end

  private

  # TODO Remove later
  class ContainStrangeUid < StandardError
  end

  class StrangeHttpTimeout < StandardError
  end

  class RetryExhausted < StandardError
  end

  class MessageWillBeResent < StandardError
  end

  class EnhanceYourCalm < StandardError
  end
end
