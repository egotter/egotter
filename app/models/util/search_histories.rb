module Util
  class SearchHistories
    attr_reader :redis

    TTL = Rails.env.development? ? 1.minute : 5.minutes

    def initialize(redis)
      @redis = redis
    end

    def normalize_key(user_id)
      "search_histories:#{user_id}"
    end

    def exists?(user_id)
      redis.exists(normalize_key(user_id))
    end

    def set(user_id, json)
      redis.setex(normalize_key(user_id), TTL, json)
    end

    def get(user_id)
      redis.get(normalize_key(user_id))
    end
  end
end