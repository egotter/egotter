require 'forwardable'
require 'singleton'

class DirectMessageLimitedFlag
  include Singleton

  TTL = 1.hour

  def initialize
    @redis = RedisClient.new
    @key = "#{Rails.env}:DirectMessageLimitedFlag"
  end

  def on
    @redis.setex(@key, TTL, true)
  end

  def on?
    @redis.exists?(@key)
  end

  def remaining
    @redis.ttl(@key)
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :on?, :remaining
  end
end
