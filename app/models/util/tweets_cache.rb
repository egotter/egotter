module Util
  class TweetsCache
    attr_reader :redis

    TTL = Rails.env.development? ? 5.minutes : 1.day

    def initialize(redis)
      @redis = redis
    end

    class << self
      def exists?(word)
        new(Redis.client).exists?(word)
      end

      def set(word, json)
        new(Redis.client).set(word, json)
      end

      def get(word)
        new(Redis.client).get(word)
      end
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