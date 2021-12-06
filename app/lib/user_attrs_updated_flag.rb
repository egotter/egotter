require 'singleton'

class UserAttrsUpdatedFlag
  include Singleton

  TTL = 1.hour

  def initialize
    @redis = RedisClient.new
  end

  def on(user_id)
    @redis.setex(key(user_id), TTL, true)
  end

  def on?(user_id)
    @redis.exists?(key(user_id))
  end

  def key(val)
    "#{Rails.env}:UserAttrsUpdatedFlag:#{val}"
  end

  class << self
    def on(user_id)
      instance.on(user_id)
    end

    def on?(user_id)
      instance.on?(user_id)
    end
  end
end
