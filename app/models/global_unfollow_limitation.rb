class GlobalUnfollowLimitation

  def initialize
    @redis = Redis.client

    @ttl = 1.hour
    @key = "#{Rails.env}:#{self.class}:#{@ttl}"
  end

  def limit_start
    @redis.setex(@key, @ttl, true)
  end

  def limited?
    @redis.exists(@key)
  end

  def remaining
    @redis.ttl(@key)
  end
end
