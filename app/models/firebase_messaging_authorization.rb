class FirebaseMessagingAuthorization

  def initialize
    @redis = self.class.redis_instance
    @ttl = 59.minutes
    @key = "#{Rails.env}:#{self.class}"
  end

  def clear
    @redis.del(@key)
  end

  def fetch
    if block_given?
      if @redis.exists?(@key)
        @redis.get(@key)
      else
        block_result = yield
        @redis.setex(@key, @ttl, block_result)
        block_result
      end
    else
      @redis.get(@key)
    end
  end

  class << self
    def redis_instance
      @redis_instance ||= RedisClient.new
    end
  end
end
