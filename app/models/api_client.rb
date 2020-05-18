require 'active_support/cache/redis_cache_store'

class ApiClient
  def initialize(client)
    @client = client
    @retries = Hash.new(0)
  end

  def create_direct_message_event(*args)
    request_with_retry_handler(__method__) do
      resp = @client.twitter.create_direct_message_event(*args).to_h
      DirectMessage.new(event: resp)
    end
  end

  def method_missing(method, *args, &block)
    if @client.respond_to?(method)
      request_with_retry_handler(method) do
        # client#parallel uses block
        @client.send(method, *args, &block)
      end
    else
      super
    end
  end

  def request_with_retry_handler(method, &block)
    yield
  rescue => e
    @retries[method] += 1
    update_authorization_status(e)
    handle_retryable_error(e, method)
    retry
  end

  def update_authorization_status(e)
    if AccountStatus.unauthorized?(e)
      if (user = User.select(:id).find_by_token(@client.access_token, @client.access_token_secret))
        UpdateAuthorizedWorker.perform_async(user.id)
      end
    end
  end

  MAX_RETRIES = 3

  def handle_retryable_error(e, method_name)
    if ServiceStatus.retryable_error?(e)
      if @retries[method_name] > MAX_RETRIES
        raise RetryExhausted.new("#{e.inspect} method=#{method_name} retries=#{@retries[method_name]}")
      else
        # Do nothing
      end
    else
      raise e
    end
  end

  class RetryExhausted < StandardError
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
      client =
          if options.blank?
            TwitterWithAutoPagination::Client.new
          else
            options[:cache_store] = CacheStore.new
            TwitterWithAutoPagination::Client.new(config(options))
          end
      new(client)
    end
  end

  private

  class CacheStore < ActiveSupport::Cache::RedisCacheStore
    def initialize
      super(
          namespace: "#{Rails.env}:twitter",
          expires_in: 20.minutes,
          race_condition_ttl: 3.minutes,
          redis: self.class.redis_client
      )
    end

    class << self
      # Intentionally not cached
      def redis_client
        Redis.client(ENV['TWITTER_API_REDIS_HOST'])
      end
    end

    module RescueAllRedisErrors
      %i(
        read
        write
      ).each do |method_name|
        define_method(method_name) do |*args, &blk|
          super(*args, &blk)
        rescue => e
          Rails.logger.warn "Rescue all errors in #{self.class}##{method_name} #{e.inspect}"
          nil
        end
      end
    end
    prepend RescueAllRedisErrors
  end
end
