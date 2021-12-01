require 'twitter_with_auto_pagination'

class ApiClient
  def initialize(client, user = nil)
    @client = client
    @user = user
  end

  def create_direct_message(recipient_id, message, async: false)
    if async
      request = CreateDirectMessageRequest.create(sender_id: @user&.uid, recipient_id: recipient_id, properties: {message: message})
      request.perform
    else
      twitter.create_direct_message_event(recipient_id, message)
      GlobalSendDirectMessageCountByUser.new.increment(recipient_id) if recipient_id != User::EGOTTER_UID
      CreateDirectMessageEventWorker.perform_async(@user&.uid, recipient_id, nil, Time.zone.now)
      CreateDirectMessageSendLogWorker.perform_async(sender_id: @user&.uid, recipient_id: recipient_id, message: message)
      true
    end
  rescue => e
    CreateDirectMessageErrorLogWorker.perform_async([recipient_id, message], e.class, e.message, Time.zone.now, sender_id: @user&.uid)
    update_blocker_status(e)

    if e.class == ApiClient::RetryExhausted
      Rails.logger.warn "Sending a DM failed method=#{__method__} user_id=#{@user&.id} recipient_id=#{recipient_id} message=#{message}"
    end

    raise
  end

  def create_direct_message_event(event:)
    resp = twitter.create_direct_message_event(event: event).to_h
    dm = DirectMessageWrapper.new(event: resp)
    GlobalSendDirectMessageCountByUser.new.increment(dm.recipient_id) if dm.recipient_id != User::EGOTTER_UID
    CreateDirectMessageEventWorker.perform_async(dm.sender_id, dm.recipient_id, nil, Time.zone.now)
    CreateDirectMessageSendLogWorker.perform_async(sender_id: dm.sender_id, recipient_id: dm.recipient_id, message: dm.text)
    dm
  rescue => e
    CreateDirectMessageErrorLogWorker.perform_async({event: event}, e.class, e.message, Time.zone.now, sender_id: @user&.uid)
    update_blocker_status(e)

    if e.class == ApiClient::RetryExhausted
      Rails.logger.warn "Sending a DM failed method=#{__method__} user_id=#{@user&.id} event=#{event.inspect}"
    end

    raise
  end

  def method_missing(method, *args, &block)
    if @client.respond_to?(method)
      RequestWithRetryHandler.new(method).perform do
        # client#parallel uses block
        @client.send(method, *args, &block)
      end
    else
      super
    end
  rescue => e
    update_authorization_status(e)
    update_lock_status(e)
    create_not_found_user(e, method, *args)
    create_forbidden_user(e, method, *args)
    raise
  end

  def update_blocker_status(e)
    if DirectMessageStatus.you_have_blocked?(e) && (user = fetch_user)
      CreateEgotterBlockerWorker.perform_async(user.uid)
      CreateViolationEventWorker.perform_async(user.id, 'Blocking egotter')
    end
  end

  def update_authorization_status(e)
    if TwitterApiStatus.unauthorized?(e) && (user = fetch_user)
      UpdateUserAttrsWorker.perform_async(user.id)
    end
  end

  def update_lock_status(e)
    if TwitterApiStatus.temporarily_locked?(e) && (user = fetch_user)
      UpdateLockedWorker.perform_async(user.id)
    end
  end

  def create_not_found_user(e, method, *args)
    if TwitterApiStatus.not_found?(e) && method == :user && args.length >= 1 && args[0].is_a?(String)
      CreateNotFoundUserWorker.perform_async(args[0], location: (caller[2][/`([^']*)'/, 1] rescue ''))
    end
  end

  def create_forbidden_user(e, method, *args)
    if TwitterApiStatus.suspended?(e) && method == :user && args.length >= 1 && args[0].is_a?(String)
      CreateForbiddenUserWorker.perform_async(args[0], location: (caller[2][/`([^']*)'/, 1] rescue ''))
    end
  end

  # TODO Use @user
  def fetch_user
    User.find_by_token(@client.access_token, @client.access_token_secret)
  end

  def twitter
    TwitterWrapper.new(self, @client.twitter)
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
          options[:cache_store] = ApiClientCacheStore.new
        end
        client = TwitterWithAutoPagination::Client.new(config(options))
      end

      new(client, options[:user])
    end

    def cs_client
      client = TwitterWithAutoPagination::Client.new(
          consumer_key: ENV['TWITTER_API_KEY_CS'],
          consumer_secret: ENV['TWITTER_API_SECRET_CS'],
          access_token: ENV['TWITTER_ACCESS_TOKEN_CS'],
          access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET_CS'],
          timeouts: {connect: 1, read: 2, write: 4})
      new(client, User.egotter_cs)
    end
  end

  private

  class TwitterWrapper
    attr_reader :api_name

    def initialize(api_client, twitter)
      @api_client = api_client
      @twitter = twitter
      @api_name = nil
    end

    [:user_agent, :user_token?, :credentials, :proxy, :timeouts].each do |method_name|
      define_method(method_name) do |*args, &blk|
        @twitter.send(method_name, *args, &blk)
      end
    end

    # TODO List api methods
    def method_missing(method, *args, &block)
      if @twitter.respond_to?(method)
        @api_name = method

        RequestWithRetryHandler.new(method).perform do
          @twitter.send(method, *args, &block)
        end
      else
        super
      end
    rescue => e
      @api_client.update_authorization_status(e)
      @api_client.update_lock_status(e)
      raise
    end
  end

  class ContainStrangeUid < StandardError
  end

  class RetryExhausted < StandardError
  end

  class RequestWithRetryHandler
    def initialize(method)
      @method = method
      @retries = 0
    end

    def perform(&block)
      ApplicationRecord.benchmark("Benchmark RequestWithRetryHandler#perform method=#{@method}", level: :info) do
        yield
      end
    rescue => e
      @retries += 1
      handle_retryable_error(e)
      retry
    end

    private

    MAX_RETRIES = 3

    def handle_retryable_error(e)
      if ServiceStatus.http_timeout?(e) && @method == :users
        raise ContainStrangeUid.new('It may contain a uid that always causes an error.')
      elsif ServiceStatus.retryable_error?(e)
        if @retries > MAX_RETRIES
          raise RetryExhausted.new("#{e.inspect} method=#{@method} retries=#{@retries}")
        else
          Rails.logger.info "RequestWithRetryHandler#perform: This error is retryable. error=#{e.class} method=#{@method}"
        end
      else
        raise e
      end
    end
  end
end
