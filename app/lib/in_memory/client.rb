module InMemory
  class Client
    def initialize(klass)
      @klass = klass
      @key_prefix = "#{Rails.env}:#{self.class}:#{@klass}"
      @redis = self.class.redis
      @retries = 0
    end

    def read(key)
      @redis.get(db_key(key))
    rescue => e
      handle_error(e)
      retry
    end

    def write(key, item)
      @redis.setex(db_key(key), ::InMemory.ttl_with_random, item)
    rescue => e
      handle_error(e)
      retry
    end

    def delete(key)
      @redis.del(db_key(key))
    rescue => e
      handle_error(e)
      retry
    end

    private

    def db_key(key)
      "#{@key_prefix}:#{key}"
    end

    def handle_error(e)
      # Redis::TimeoutError
      if e.class.to_s.downcase.include?('timeout') && (@retries += 1) <= 3
        nil
      else
        raise e
      end
    end

    class << self
      def redis
        @redis ||= Redis.client(::InMemory.redis_hostname)
      end
    end
  end
end
