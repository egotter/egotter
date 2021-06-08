require 'twitter_with_auto_pagination'

class ApiClient
  def initialize(client)
    @client = client
  end

  def create_direct_message(recipient_id, message)
    resp = twitter.create_direct_message_event(recipient_id, message).to_h
    DirectMessage.new(event: resp)
  rescue => e
    CreateDirectMessageErrorLogWorker.perform_async([recipient_id, message], e.class, e.message, Time.zone.now, sender_id: recipient_id)
    update_blocker_status(e)
    raise
  end

  def create_direct_message_event(*args)
    resp = twitter.create_direct_message_event(*args).to_h
    DirectMessage.new(event: resp)
  rescue => e
    if (user = fetch_user)
      CreateDirectMessageErrorLogWorker.perform_async(args, e.class, e.message, Time.zone.now, sender_id: user.uid)
    end
    update_blocker_status(e)
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
    end
  end

  def update_authorization_status(e)
    if TwitterApiStatus.unauthorized?(e) && (user = fetch_user)
      UpdateAuthorizedWorker.perform_async(user.id)
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

      new(client)
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
