class TwitterUserUpdatedFlag
  class << self
    def on(uid)
      redis.setex(key(uid), ttl, true)
    rescue => e
      nil
    end

    def on?(uid)
      redis.exists?(key(uid))
    rescue => e
      false
    end

    def key(val)
      "#{Rails.env}:#{self}:#{val}"
    end

    def ttl
      30.minutes
    end

    def redis
      @redis ||= Redis.client
    end
  end
end