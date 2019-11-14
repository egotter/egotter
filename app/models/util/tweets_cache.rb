module Util
  class TweetsCache
    attr_reader :redis

    TTL = Rails.env.development? ? 10.minute : 1.hour

    def initialize(redis)
      @redis = redis
    end

    class << self
      def instance
        new(Redis.client)
      end

      def ttl(word)
        instance.ttl(word)
      end

      def exists?(word)
        instance.exists?(word)
      end

      def set(word, json)
        instance.set(word, json)
      end

      def get(word)
        instance.get(word)
      end
    end

    def ttl(word)
      redis.ttl(normalize_key(word))
    end

    def normalize_key(word)
      "tweets_cache_for:#{word}"
    end

    def exists?(word)
      redis.exists(normalize_key(word))
    end

    def set(word, json)
      redis.setex(normalize_key(word), TTL, json)
    end

    def get(word)
      redis.get(normalize_key(word))
    end
  end
end