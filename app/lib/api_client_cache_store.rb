require 'active_support'
require 'active_support/cache/redis_cache_store'

class ApiClientCacheStore < ActiveSupport::Cache::RedisCacheStore
  ERROR_HANDLER = Proc.new do |method:, returning:, exception:|
    Airbag.warn "ApiClient::CacheStore: #{method} failed, returned #{returning.inspect}: #{exception.class}: #{exception.message}"
  end

  def initialize
    super(
        namespace: "#{Rails.env}:twitter",
        expires_in: 20.minutes,
        race_condition_ttl: 3.minutes,
        redis: self.class.redis,
        error_handler: ERROR_HANDLER
    )
  end

  class << self
    MX = Mutex.new

    def redis
      MX.synchronize do
        unless @redis
          @redis = RedisClient.new(host: ENV['TWITTER_API_REDIS_HOST'], db: 2)
        end
      end
      @redis
    end
  end
end
