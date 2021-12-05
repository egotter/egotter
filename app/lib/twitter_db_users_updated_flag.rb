require 'digest/md5'

class TwitterDBUsersUpdatedFlag
  class << self
    def on(uids)
      redis.setex(key(uids), ttl, true)
    rescue => e
      nil
    end

    def on?(uids)
      redis.exists?(key(uids))
    rescue => e
      false
    end

    def key(val)
      "#{Rails.env}:#{self}:#{Digest::MD5.hexdigest(val.to_s)}"
    end

    def ttl
      1.hour
    end

    MX = Mutex.new

    def redis
      MX.synchronize do
        unless @redis
          @redis = RedisClient.new
        end
      end
      @redis
    end
  end
end
