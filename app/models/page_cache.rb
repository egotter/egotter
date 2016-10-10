class PageCache
  TTL = Rails.configuration.x.constants['page_cache_ttl']

  attr_reader :redis

  def initialize(redis)
    @redis = redis
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
    ENV['PAGE_CACHE'] == '1' && redis.exists(normalize_key(uid))
  end

  def read(uid)
    result = redis.get(normalize_key(uid))
    touch(uid) if result
    result
  end

  def write(uid, html)
    redis.setex(normalize_key(uid), TTL, html)
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
    redis.del(normalize_key(uid))
  end

  def clear
    keys = redis.keys("#{key_prefix}:*")
    redis.del(keys) if keys.any?
  end

  def ttl(uid)
    redis.ttl(normalize_key(uid))
  end

  def touch(uid)
    redis.expire(normalize_key(uid), TTL)
  end
end