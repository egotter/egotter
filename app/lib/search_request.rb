class SearchRequest
  def initialize
    @store = ActiveSupport::Cache::RedisCacheStore.new(
        namespace: "#{Rails.env}:search_request",
        expires_in: 10.minutes,
        redis: self.class.redis
    )
  end

  def exists?(screen_name)
    @store.exist?(screen_name)
  end

  def write(screen_name)
    @store.write(screen_name, true)
  end

  class << self
    MX = Mutex.new

    def redis
      MX.synchronize do
        unless @redis
          @redis = RedisClient.new
        end
      end
      @redis
    end
  end
end
