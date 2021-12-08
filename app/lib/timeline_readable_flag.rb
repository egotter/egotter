require 'forwardable'
require 'singleton'

class TimelineReadableFlag
  include Singleton

  TTL = 5.minutes
  ON = '1'
  OFF = '2'

  def initialize
    @redis = RedisClient.new(host: ENV['TWITTER_API_REDIS_HOST'], db: 3)
  end

  def on(user_id, uid)
    @redis.setex(key(user_id, uid), TTL, ON)
  end

  def off(user_id, uid)
    @redis.setex(key(user_id, uid), TTL, OFF)
  end

  def clear(user_id, uid)
    @redis.del(key(user_id, uid))
  end

  def on?(user_id, uid)
    @redis.get(key(user_id, uid)) == ON
  end

  def off?(user_id, uid)
    @redis.get(key(user_id, uid)) == OFF
  end

  def key(user_id, uid)
    "#{Rails.env}:TimelineReadableFlag:#{user_id}:uid-#{uid}"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :off, :clear, :on?, :off?
  end
end
