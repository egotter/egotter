module Util
  class SearchCountCache
    attr_reader :redis

    TTL = Rails.env.development? ? 5.minutes : 1.hour

    def initialize(redis)
      @redis = redis
    end

    class << self
      def exists?
        new(Redis.client).exists?
      end

      def set(num)
        new(Redis.client).set(num)
      end

      def get
        new(Redis.client).get.to_i
      end

      def increment
        new(Redis.client).increment
      end
    end

    def key
      "search_count_cache"
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
      redis.incr(key)
    end
  end
end