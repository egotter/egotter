require 'forwardable'
require 'singleton'

class DirectMessageSendCounter
  include Singleton

  TTL = 1.day

  def initialize
    @redis = RedisClient.new
  end

  def increment(uid)
    k = key(uid)
    @redis.pipelined do
      @redis.incr(k)
      @redis.expire(k, TTL)
    end
  rescue => e
    @redis.expire(k, TTL) rescue nil
    nil
  end

  def count(uid)
    @redis.get(key(uid))&.to_i || 0
  rescue => e
    0
  end

  def clear(uid)
    @redis.del(key(uid))
  end

  # For testing
  def ttl(uid)
    @redis.ttl(key(uid))
  end

  def key(val)
    "#{Rails.env}:DirectMessageSendCounter:#{val}"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :increment, :count, :clear, :ttl
  end
end
