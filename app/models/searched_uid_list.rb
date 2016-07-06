# Sorted Set
class SearchedUidList
  KEY = Redis.foreground_search_searched_uids_key
  TTL = Rails.configuration.x.constants['background_search_worker_recently_searched_threshold']

  attr_reader :redis

  def initialize(redis)
    @redis = redis
  end

  def clear
    redis.del(KEY)
  end

  def cleanup
    redis.zremrangebyscore(KEY, 0, Time.zone.now.to_i - TTL)
  end

  def exists?(uid, user_id)
    cleanup
    redis.zrank(KEY, "#{user_id}:#{uid}").present?
  end

  def add(uid, user_id)
    cleanup
    redis.zadd(KEY, Time.zone.now.to_i, "#{user_id}:#{uid}")
  end

  def delete(uid)
    redis.zrem(KEY, uid.to_s)
  end

  def to_a
    redis.zrangebyscore(KEY, 0, Time.zone.now.to_i)
  end
end