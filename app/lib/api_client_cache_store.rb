require 'singleton'

class ApiClientCacheStore < ActiveSupport::Cache::RedisCacheStore
  include Singleton

  def initialize
    super(
        namespace: "#{Rails.env}:twitter",
        expires_in: 20.minutes,
        race_condition_ttl: 3.minutes,
        redis: RedisClient.new(host: ENV['TWITTER_API_REDIS_HOST'], db: 2)
    )
  end
end
