require 'forwardable'
require 'singleton'

class LoginCounter
  include Singleton

  def initialize
    @redis = RedisClient.new
  end

  def value(id)
    @redis.get(key(id))&.to_i || 0
  end

  def increment(id)
    k = key(id)
    @redis.multi do |r|
      r.incr(k)
      r.expire(k, 200)
    end
  end

  private

  def key(id)
    "#{Rails.env}:LoginCounter:#{id || Time.zone.now.to_f }"
  end

  class << self
    extend Forwardable
    def_delegators :instance, :value, :increment
  end
end
