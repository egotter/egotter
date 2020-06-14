require_relative './logging'

module UniqueJob
  class JobHistory
    def initialize(worker_class, queueing_class, ttl)
      @key = "#{self.class}:#{queueing_class}:#{worker_class}"
      @ttl = ttl
    end

    def ttl(val = nil)
      if val
        redis.ttl(key(val))
      else
        @ttl
      end
    end

    def delete_all
      redis.keys("#{@key}:*").each do |key|
        redis.del(key)
      end
    end

    def exists?(val)
      redis.exists(key(val))
    end

    def add(val)
      redis.setex(key(val), @ttl, true)
    end

    private

    def key(val)
      "#{@key}:#{val}"
    end

    def redis
      self.class.redis
    end

    class << self
      def redis
        @redis ||= Redis.client(ENV['REDIS_HOST'])
      end
    end

    module RescueAllRedisErrors
      include Logging

      %i(
        ttl
        exists?
        add
      ).each do |method_name|
        define_method(method_name) do |*args, &blk|
          start = Time.now
          super(*args, &blk)
        rescue => e
          elapsed = Time.now - start
          logger.warn "Rescue all errors in #{self.class}##{method_name} #{e.inspect} elapsed=#{sprintf("%.3f sec", elapsed)}"
          logger.debug { e.backtrace.join("\n") }
          nil
        end
      end
    end
    prepend RescueAllRedisErrors
  end
end
