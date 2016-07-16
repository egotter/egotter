# Sorted Set
class UidList
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

  def clear
    redis.del(key)
  end

  def cleanup
    redis.zremrangebyscore(key, 0, Time.zone.now.to_i - ttl)
  end

  def exists?(uid, user_id)
    cleanup
    redis.zrank(key, "#{user_id}:#{uid}").present?
  end

  def add(uid, user_id)
    cleanup
    redis.zadd(key, Time.zone.now.to_i, "#{user_id}:#{uid}")
  end

  def delete(uid)
    redis.zrem(key, uid.to_s)
  end

  def to_a
    cleanup
    redis.zrangebyscore(key, 0, Time.zone.now.to_i)
  end

  def size
    to_a.size
  end
end