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

    MX = Mutex.new

    def redis
      MX.synchronize do
        unless @redis
          @redis = Redis.client
        end
      end
      @redis
    end
  end
end
