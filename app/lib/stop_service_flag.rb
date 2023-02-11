require 'forwardable'
require 'singleton'

class StopServiceFlag
  include Singleton

  TTL = 3600

  def initialize
    @key = 'StopServiceFlag'
    @redis = RedisClient.new
  end

  def on
    @redis.setex(@key, TTL, true)
  rescue => e
    nil
  end

  def off
    @redis.del(@key)
  rescue => e
    nil
  end

  def on?
    @redis.exists?(@key)
  rescue => e
    false
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :off, :on?
  end
end
