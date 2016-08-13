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

  def normalize_key(uid, user_id)
    "#{key_prefix}:#{user_id}:#{uid}:#{key_suffix}"
  end

  def exists?(uid, user_id)
    ENV['PAGE_CACHE'] == '1' && redis.exists(normalize_key(uid, user_id))
  end

  def read(uid, user_id)
    result = redis.get(normalize_key(uid, user_id))
    touch(uid, user_id) if result
    result
  end

  def write(uid, user_id, html)
    redis.setex(normalize_key(uid, user_id), TTL, html)
  end

  def fetch(uid, user_id)
    if block_given?
      if exists?(uid, user_id)
        read(uid, user_id)
      else
        block_result = yield
        write(uid, user_id, block_result)
        block_result
      end
    else
      read(uid, user_id)
    end
  end

  def delete(uid, user_id)
    redis.del(normalize_key(uid, user_id))
  end

  def clear
    keys = redis.keys("#{key_prefix}:*")
    redis.del(keys) if keys.any?
  end

  def ttl(uid, user_id)
    redis.ttl(normalize_key(uid, user_id))
  end

  def touch(uid, user_id)
    redis.expire(normalize_key(uid, user_id), TTL)
  end
end