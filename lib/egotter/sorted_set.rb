module Egotter
  class SortedSet
    attr_reader :redis, :key

    def initialize(redis)
      @redis = redis
      @key = nil
      @ttl = nil
    end

    def ttl(val = nil)
      if val
        ttl - (Time.zone.now.to_i - redis.zscore(key, val.to_s))
      else
        @ttl
      end
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
