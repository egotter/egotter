require 'forwardable'
require 'singleton'

class TwitterUserUpdatedFlag
  include Singleton

  TTL = 30.minutes

  def initialize
    @redis = RedisClient.new
  end

  def on(uid)
    @redis.setex(key(uid), TTL, true)
  rescue => e
    nil
  end

  def on?(uid)
    @redis.exists?(key(uid))
  rescue => e
    false
  end

  def key(val)
    "#{Rails.env}:TwitterUserUpdatedFlag:#{val}"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :on?
  end
end
