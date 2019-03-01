module Util
  class OriginalSortedSet
    attr_reader :redis

    def initialize(redis)
      @redis = redis
      @ttl = (Rails.env.production? ? 1.hour : 10.minutes)
    end

    def key
      @key
    end

    def ttl
      @ttl
    end

    def clear
      redis.del(key)
    end

    def cleanup
      redis.zremrangebyscore(key, 0, Time.zone.now.to_i - ttl)
    end

    def exists?(val)
      cleanup
      redis.zrank(key, val.to_s).present?
    end

    def add(val)
      cleanup
      redis.zadd(key, Time.zone.now.to_i, val.to_s)
    end

    def delete(val)
      redis.zrem(key, val.to_s)
    end

    def to_a
      cleanup
      redis.zrangebyscore(key, 0, Time.zone.now.to_i)
    end

    def size
      to_a.size
    end
  end
end
