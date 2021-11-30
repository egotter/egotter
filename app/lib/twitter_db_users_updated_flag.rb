require 'digest/md5'

class TwitterDBUsersUpdatedFlag
  class << self
    def on(uids)
      redis.setex(key(uids), ttl, true)
    end

    def on?(uids)
      redis.exists?(key(uids))
    end

    def key(val)
      "#{Rails.env}:#{self}:#{Digest::MD5.hexdigest(val.to_s)}"
    end

    def ttl
      1.hour
    end

    def redis
      @redis ||= Redis.client
    end
  end
end
