class LoginCounter
  def initialize(id)
    @key = "LoginCounter:#{id || Time.zone.now.to_f }"
    @redis = self.class.redis
  end

  def value
    @redis.get(@key)&.to_i || 0
  end

  def increment
    @redis.multi do |r|
      r.incr(@key)
      r.expire(@key, 200)
    end
  end

  LOCK = Mutex.new

  class << self
    def redis
      LOCK.synchronize do
        @redis ||= RedisClient.new
      end
    end
  end
end
