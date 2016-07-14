class PageCache
  TTL = Rails.configuration.x.constants['page_cache_ttl']

  attr_reader :redis

  def initialize(redis)
    @redis = redis
  end

  def key(uid, user_id)
    "searches:show:#{user_id}:#{uid}"
  end

  def exists?(uid, user_id)
    redis.exists(key(uid, user_id))
  end

  def read(uid, user_id)
    redis.get(key(uid, user_id))
  end

  def write(uid, user_id, html)
    redis.setex(key(uid, user_id), TTL, html)
  end

  def delete(uid, user_id)
    redis.del(key(uid, user_id))
  end

  def clear
    keys = redis.keys('searches:*')
    redis.del(keys) if keys.any?
  end

  def ttl(uid, user_id)
    redis.ttl(key(uid, user_id))
  end
end