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
    raise
  end

  def update_authorization_status(e)
    if AccountStatus.unauthorized?(e)
      if (user = User.select(:id).find_by_token(@client.access_token, @client.access_token_secret))
        UpdateAuthorizedWorker.perform_async(user.id)
      end
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

  class TwitterWrapper
    def initialize(api_client, twitter)
      @api_client = api_client
      @twitter = twitter
    end

    def method_missing(method, *args, &block)
      if @twitter.respond_to?(method)
        RequestWithRetryHandler.new(method).perform do
          @twitter.send(method, *args, &block)
        end
      else
        super
      end
    rescue => e
      @api_client.update_authorization_status(e)
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
          Rails.logger.debug { e.backtrace.join("\n") }
          nil
        end
      end
    end
    prepend RescueAllRedisErrors
  end
end
