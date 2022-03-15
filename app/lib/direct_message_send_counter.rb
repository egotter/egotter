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
    @redis.pipelined do |pipeline|
      pipeline.incr(k)
      pipeline.expire(k, TTL)
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

  def sent_count(uid)
    count(uid)
  end

  def remaining_count(uid)
    5 - count(uid)
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
    def_delegators :instance, :increment, :sent_count, :remaining_count, :clear, :ttl

    def messages_left?(uid)
      remaining_count(uid) >= 1
    end
  end
end
