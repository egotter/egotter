class GlobalSendDirectMessageCountByUser

  def initialize
    @redis = Redis.client
    @key = "#{Rails.env}:#{self.class}"
  end

  def increment(uid)
    @redis.hincrby(@key, uid, 1)
  end

  def clear(uid)
    @redis.hdel(@key, uid)
  end

  def count(uid)
    val = @redis.hget(@key, uid)
    val ? val.to_i : 0
  end

  def keys
    @redis.hkeys(@key).map(&:to_i)
  end

  def values
    @redis.hvals(@key).map(&:to_i)
  end

  def soft_limited?(uid)
    count(uid) >= 4
  end

  def hard_limited?(uid)
    count(uid) >= 5
  end

  module RescueAllRedisErrors
    %i(
        increment
        clear
        count
        soft_limited?
        hard_limited?
      ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        super(*args, &blk)
      rescue => e
        Rails.logger.warn "Rescue all errors in #{self.class}##{method_name} #{e.inspect}"
        if method_name == :count
          -1
        else
          nil
        end
      end
    end
  end
  prepend RescueAllRedisErrors
end
