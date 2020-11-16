require 'active_support'
require 'active_support/cache/redis_cache_store'

require 'twitter_with_auto_pagination'

class ApiClient
  def initialize(client)
    @client = client
  end

  def create_direct_message_event(*args)
    resp = twitter.create_direct_message_event(*args).to_h
    DirectMessage.new(event: resp)
  end

  def direct_message(id)
    event = twitter.direct_message_event(id)
    DirectMessage.from_event(event.to_h)
  end

  def direct_messages
    events = twitter.direct_messages_events
    events.map { |e| DirectMessage.from_event(e.to_h) }
  end

  CONVERT_TIME_FORMAT = Proc.new do |time|
    min = time.min - (time.min % 15) # 0, 15, 30, 45
    time.strftime('%Y-%m-%d_%H:') + min.to_s.rjust(2, '0') + ':00_UTC'
  end

  def search(query, options = {})
    options[:count] = 100 unless options[:count]
    query += " since:#{CONVERT_TIME_FORMAT.call(options.delete(:since))}" if options[:since]
    query += " until:#{CONVERT_TIME_FORMAT.call(options.delete(:until))}" if options[:until]
    @client.search(query, options)
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

  def update_authorization_status(e)
    if TwitterApiStatus.unauthorized?(e)
      if (user = User.select(:id).find_by_token(@client.access_token, @client.access_token_secret))
        UpdateAuthorizedWorker.perform_async(user.id)
      end
    end
  end

  def update_lock_status(e)
    if TwitterApiStatus.temporarily_locked?(e)
      if (user = User.select(:id).find_by_token(@client.access_token, @client.access_token_secret))
        UpdateLockedWorker.perform_async(user.id)
      end
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

  def twitter
    TwitterWrapper.new(self, @client.twitter)
  end

  class << self
    def config(options = {})
      {
          consumer_key: ENV['TWITTER_CONSUMER_KEY'],
          consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
          access_token: nil,
          access_token_secret: nil
      }.merge(options)
    end

    def instance(options = {})
      if options.blank?
        client = TwitterWithAutoPagination::Client.new
      else
        if options[:cache_store] == :null_store
          options[:cache_store] = ActiveSupport::Cache::NullStore.new
        else
          options[:cache_store] = CacheStore.new
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

  class RequestWithRetryHandler
    def initialize(method)
      @method = method
      @retries = 0
    end

    def perform(&block)
      yield
    rescue => e
      @retries += 1
      handle_retryable_error(e)
      retry
    end

    private

    MAX_RETRIES = 3

    def handle_retryable_error(e)
      if ServiceStatus.retryable_error?(e)
        if @retries > MAX_RETRIES
          raise RetryExhausted.new("#{e.inspect} method=#{@method} retries=#{@retries}")
        else
          # Do nothing
        end
      else
        raise e
      end
    end

    class RetryExhausted < StandardError
    end
  end

  class CacheStore < ActiveSupport::Cache::RedisCacheStore
    ERROR_HANDLER = Proc.new do |method:, returning:, exception:|
      Rails.logger.warn "ApiClient::CacheStore: #{method} failed, returned #{returning.inspect}: #{exception.class}: #{exception.message}"
    end

    def initialize
      super(
          namespace: "#{Rails.env}:twitter",
          expires_in: 20.minutes,
          race_condition_ttl: 3.minutes,
          redis: self.class.redis_client,
          error_handler: ERROR_HANDLER
      )
    end

    class << self
      def redis_client
        @redis_client ||= Redis.client(ENV['TWITTER_API_REDIS_HOST'], db: 2)
      end

      def remove_redis_client
        @redis_client = nil
      end
    end

    module Benchmark
      %i(
        read
        write
        fetch
      ).each do |method_name|
        define_method(method_name) do |*args, &blk|
          ApplicationRecord.benchmark("#{self.class}##{__method__} key=#{args[0]}", level: :debug) do
            super(*args, &blk)
          end
        end
      end
    end
    prepend Benchmark
  end
end
