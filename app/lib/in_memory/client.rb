module InMemory
  class Client
    def initialize(redis, namespace)
      @key_prefix = "#{Rails.env}:#{self.class}:#{namespace}"
      @redis = redis
      @retries = 0
    end

    def read(key)
      @redis.get(db_key(key))
    rescue => e
      error_handler(__method__, e)
      (timeout?(e) && !retry_exhausted?) ? retry : raise
    end

    def write(key, item)
      @redis.setex(db_key(key), ::InMemory.ttl_with_random, item)
    rescue => e
      error_handler(__method__, e)
      (timeout?(e) && !retry_exhausted?) ? retry : raise
    end

    def delete(key)
      @redis.del(db_key(key))
    rescue => e
      error_handler(__method__, e)
      (timeout?(e) && !retry_exhausted?) ? retry : raise
    end

    private

    def db_key(key)
      "#{@key_prefix}:#{key}"
    end

    def error_handler(method, e)
      Rails.logger.info "InMemory::Client: Failed method=#{method} exception=#{e.inspect}"
    end

    def timeout?(e)
      e.class.to_s.downcase.include?('timeout')
    end

    def retry_exhausted?
      (@retries += 1) > 3
    end
  end
end
