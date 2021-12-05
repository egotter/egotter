module Egotter
  class SortedSet
    attr_reader :key

    def initialize(redis = nil)
      @redis = redis || self.class.redis
      @key = nil
      @ttl = nil
    end

    def ttl(val = nil)
      if val
        score = @redis.zscore(key, val.to_s)
        score ? (ttl - (current_time - score)) : nil
      else
        @ttl
      end
    end

    def clear
      @redis.del(key)
    end

    def cleanup
      @redis.zremrangebyscore(key, 0, current_time - ttl)
    end

    # TODO Stop using pipeline

    def exists?(val)
      @redis.pipelined do
        cleanup
        @redis.zrank(key, val.to_s)
      end.last.present?
    end

    def add(val)
      @redis.pipelined do
        cleanup
        @redis.zadd(key, current_time, val.to_s)
      end
    end

    def delete(val)
      @redis.zrem(key, val.to_s)
    end

    def to_a
      @redis.pipelined do
        cleanup
        @redis.zrangebyscore(key, 0, current_time)
      end.last
    end

    def size
      to_a.size
    end

    class << self
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

    private

    def current_time
      Time.zone.now.to_i
    end

    module RescueAllRedisErrors
      %i(
        ttl
        clear
        cleanup
        exists?
        add
        delete
        to_a
        size
      ).each do |method_name|
        define_method(method_name) do |*args, &blk|
          super(*args, &blk)
        rescue Redis::BaseError => e
          Rails.logger.warn "Rescue all errors in #{self.class}##{method_name} #{e.inspect}"
          nil
        end
      end
    end
    prepend RescueAllRedisErrors
  end
end
