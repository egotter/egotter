module Util
  class TwitterUserSet
    attr_reader :redis

    def initialize(redis)
      @redis = redis
    end

    def self.key
      raise NotImplementedError
    end

    def key
      self.class.key
    end

    def self.ttl
      raise NotImplementedError
    end

    def ttl
      self.class.ttl
    end

    def normalize_key(uid, user_id)
      "#{key}:#{user_id}:#{uid}"
    end

    def clear
      keys = redis.keys("#{key}:*")
      redis.del(keys) if keys.any?
    end

    def cleanup
      raise NotImplementedError
    end

    def exists?(uid, user_id)
      redis.exists(normalize_key(uid, user_id))
    end

    def get(uid, user_id)
      JSON.load(redis.get(normalize_key(uid, user_id)))
    end

    def set(uid, user_id, obj)
      redis.setex(normalize_key(uid, user_id), ttl, JSON.dump(obj))
    end

    def delete(uid, user_id)
      redis.del(normalize_key(uid, user_id))
    end
  end
end