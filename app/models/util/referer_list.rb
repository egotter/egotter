module Util
  class RefererList
    attr_reader :redis

    def initialize(redis)
      @redis = redis
    end

    def self.key
      @@key ||= 'referer_list'
    end

    def key
      self.class.key
    end

    def self.ttl
      @@ttl ||= 30.minutes.to_i
    end

    def ttl
      self.class.ttl
    end

    def normalize_key(session_id)
      "#{key}:#{session_id}"
    end

    def clear
      keys = redis.keys("#{key}:*")
      redis.del(keys) if keys.any?
    end

    def cleanup
      raise NotImplementedError
    end

    def exists?(session_id)
      trim(session_id)
      redis.exists(normalize_key(session_id))
    end

    def push(session_id, str)
      trim(session_id)
      redis.rpush(normalize_key(session_id), str)
      redis.expire(normalize_key(session_id), ttl)
    end

    def delete(session_id)
      redis.del(normalize_key(session_id))
    end

    def trim(session_id)
      redis.ltrim(normalize_key(session_id), 0, 9)
    end

    def to_a(session_id)
      trim(session_id)
      redis.lrange(normalize_key(session_id), 0, -1)
    end

    def size(session_id)
      trim(session_id)
      redis.llen(normalize_key(session_id))
    end
  end
end