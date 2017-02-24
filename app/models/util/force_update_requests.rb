module Util
  class ForceUpdateRequests
    attr_reader :redis

    TTL = Rails.env.development? ? 1.minute.to_i : 1.hour.to_i

    def initialize(redis)
      @redis = redis
    end

    def normalize_key(user_id, uid)
      "force_update_requests:#{user_id}:#{uid}"
    end

    def exists?(user_id, uid)
      redis.exists(normalize_key(user_id, uid))
    end

    def add(user_id, uid)
      redis.setex(normalize_key(user_id, uid), TTL, true)
    end
  end
end