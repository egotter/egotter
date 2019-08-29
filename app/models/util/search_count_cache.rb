module Util
  class SearchCountCache
    attr_reader :redis

    TTL = Rails.env.development? ? 5.minutes : 1.hour

    def initialize(redis)
      @redis = redis
    end

    class << self
      def ttl
        instance.ttl
      end

      def exists?
        instance.exists?
      end

      def set(num)
        instance.set(num)
      end

      def get
        instance.get.to_i
      end

      def increment
        instance.increment
      end

      def instance
        new(Redis.client)
      end
    end

    def key
      "search_count_cache"
    end

    def ttl
      redis.ttl(key)
    end

    def exists?
      redis.exists(key)
    end

    def set(num)
      redis.setex(key, TTL, num)
    end

    def get
      redis.get(key)
    end

    def increment
      redis.expire(key, TTL)
      redis.incr(key)
    end
  end
end