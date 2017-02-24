module Util
  class TweetsCache
    attr_reader :redis

    TTL = Rails.env.development? ? 5.minutes : 1.day

    def initialize(redis)
      @redis = redis
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