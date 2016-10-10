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

    def normalize_key(uid)
      "#{key}:#{uid}"
    end

    def clear
      keys = redis.keys("#{key}:*")
      redis.del(keys) if keys.any?
    end

    def cleanup
      raise NotImplementedError
    end

    def exists?(uid)
      redis.exists(normalize_key(uid))
    end

    def get(uid)
      JSON.load(redis.get(normalize_key(uid)))
    end

    def set(uid, obj)
      redis.setex(normalize_key(uid), ttl, JSON.dump(obj))
    end

    def delete(uid)
      redis.del(normalize_key(uid))
    end
  end
end