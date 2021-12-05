class UserAttrsUpdatedFlag
  class << self
    def on(user_id)
      redis.setex(key(user_id), ttl, true)
    end

    def on?(user_id)
      redis.exists?(key(user_id))
    end

    def key(val)
      "#{Rails.env}:#{self}:#{val}"
    end

    def ttl
      1.hour
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
