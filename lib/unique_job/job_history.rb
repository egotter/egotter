module UniqueJob
  class JobHistory
    def initialize(worker_class, queueing_class, ttl)
      @redis = Redis.client

      @key = "#{self.class}:#{queueing_class}:#{worker_class}"
      @ttl = ttl
    end

    def ttl(val = nil)
      if val
        @redis.ttl(key(val))
      else
        @ttl
      end
    end

    def delete_all
      @redis.keys("#{@key}:*").each do |key|
        @redis.del(key)
      end
    end

    def exists?(val)
      @redis.exists(key(val))
    end

    def add(val)
      @redis.setex(key(val), @ttl, true)
    end

    private

    def key(val)
      "#{@key}:#{val}"
    end
  end
end
