require 'forwardable'
require 'singleton'

class BaseshopAccessedFlag
  include Singleton

  TTL = 12.hours

  def initialize
    @redis = RedisClient.new
  end

  def on(user_id)
    @redis.setex(key(user_id), TTL, true)
  rescue => e
    nil
  end

  def on?(user_id)
    @redis.exists?(key(user_id))
  rescue => e
    false
  end

  def key(val)
    "#{Rails.env}:BaseshopAccessedFlag:#{val}"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :on?
  end
end
