require 'forwardable'
require 'singleton'

class ConsecutiveApiNotAuthorizedFlag
  include Singleton

  TTL = 30.minutes

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
    "#{Rails.env}:ConsecutiveApiNotAuthorizedFlag:#{val}"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :on?
  end
end
