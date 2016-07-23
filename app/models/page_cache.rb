class PageCache
  TTL = Rails.configuration.x.constants['page_cache_ttl']

  attr_reader :redis

  def initialize(redis)
    @redis = redis
  end

  def key_prefix
    'searches'
  end

  def key_suffix
    'show'
  end

  def normalize_key(uid, user_id)
    "#{key_prefix}:#{user_id}:#{uid}:#{key_suffix}"
  end

  def exists?(uid, user_id)
    redis.exists(normalize_key(uid, user_id))
  end

  def read(uid, user_id)
    redis.get(normalize_key(uid, user_id))
  end

  def write(uid, user_id, html)
    redis.setex(normalize_key(uid, user_id), TTL, html)
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
end