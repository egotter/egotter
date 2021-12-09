require 'forwardable'
require 'singleton'

class TwitterUserAssembledFlag
  include Singleton

  TTL = 1.minute

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
    "#{Rails.env}:TwitterUserAssembledFlag:#{val}"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :on?
  end
end
