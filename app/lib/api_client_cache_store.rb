require 'active_support'
require 'active_support/cache/redis_cache_store'

class ApiClientCacheStore < ActiveSupport::Cache::RedisCacheStore
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

  %i(
    read
    write
    fetch
  ).each do |method_name|
    define_method(method_name) do |*args, &blk|
      ApplicationRecord.benchmark("Benchmark ApiClientCacheStore##{__method__} key=#{args[0]}", level: :info) do
        super(*args, &blk)
      end
    end
  end

  class << self
    def redis_client
      @redis_client ||= Redis.client(ENV['TWITTER_API_REDIS_HOST'], db: 2)
    end
  end
end
