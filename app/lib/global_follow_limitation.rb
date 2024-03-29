class GlobalFollowLimitation

  def initialize
    @redis = self.class.redis_instance

    @ttl = 1.hour
    @key = "#{Rails.env}:#{self.class}:#{@ttl}"
  end

  def limit_start
    @redis.setex(@key, @ttl, Time.zone.now.to_s)
  end

  def limited?
    @redis.exists?(@key)
  end

  def remaining
    @redis.ttl(@key)
  end

  class << self
    def redis_instance
      @redis_instance ||= RedisClient.new
    end
  end
end
