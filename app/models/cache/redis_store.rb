module Cache
  class RedisStore
    TTL = Rails.configuration.x.constants['page_cache_ttl']

    attr_reader :store

    def initialize
      @store = Redis.client
    end

    def key_prefix
      'searches-v2'
    end

    def key_suffix
      'show'
    end

    def normalize_key(uid)
      "#{key_prefix}:#{uid}:#{key_suffix}"
    end

    def exists?(uid)
      ENV['PAGE_CACHE'] == '1' && store.exists(normalize_key(uid))
    end

    def read(uid)
      result = store.get(normalize_key(uid))
      touch(uid) if result
      result
    end

    def write(uid, html)
      store.setex(normalize_key(uid), TTL, html)
    end

    def fetch(uid)
      if block_given?
        if exists?(uid)
          read(uid)
        else
          block_result = yield
          write(uid, block_result)
          block_result
        end
      else
        read(uid)
      end
    end

    def delete(uid)
      store.del(normalize_key(uid))
    end

    def clear
      keys = store.keys("#{key_prefix}:*")
      store.del(keys) if keys.any?
    end

    def cleanup
      raise NotImplementedError
    end

    def ttl(uid)
      store.ttl(normalize_key(uid))
    end

    def touch(uid)
      store.expire(normalize_key(uid), TTL)
    end
  end
end