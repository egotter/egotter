class DirectMessageSendCounter
  class << self
    def increment(uid)
      redis.pipelined do
        redis.incr(key(uid))
        redis.expire(key(uid), 1.day)
      end
    rescue => e
      redis.expire(key(uid), 1.day) rescue nil
      nil
    end

    def count(uid)
      redis.get(key(uid))&.to_i || 0
    rescue => e
      0
    end

    def clear(uid)
      redis.del(key(uid))
    end

    # For testing
    def ttl(uid)
      redis.ttl(key(uid))
    end

    def key(val)
      "#{Rails.env}:#{self}:#{val}"
    end

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
