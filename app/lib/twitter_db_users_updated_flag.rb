require 'singleton'
require 'digest/md5'

class TwitterDBUsersUpdatedFlag
  include Singleton

  TTL = 1.hour

  def initialize
    @redis = RedisClient.new
  end

  def on(uids)
    @redis.setex(key(uids), TTL, true)
  rescue => e
    nil
  end

  def on?(uids)
    @redis.exists?(key(uids))
  rescue => e
    false
  end

  def key(val)
    "#{Rails.env}:TwitterDBUsersUpdatedFlag:#{Digest::MD5.hexdigest(val.to_s)}"
  end

  class << self
    def on(uids)
      instance.on(uids)
    end

    def on?(uids)
      instance.on?(uids)
    end
  end
end
