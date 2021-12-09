require 'forwardable'
require 'singleton'

class TooManyFriendsSearchedFlag
  include Singleton

  TTL = 1.hour

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
    "#{Rails.env}:TooManyFriendsSearchedFlag:#{val}"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :on, :on?
  end
end
