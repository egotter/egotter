class FirebaseMessagingAuthorization

  def initialize
    @redis = Redis.client
    @ttl = 59.minutes
    @key = "#{Rails.env}:#{self.class}"
  end

  def clear
    @redis.del(@key)
  end

  def fetch
    if block_given?
      if @redis.exists(@key)
        @redis.get(@key)
      else
        block_result = yield
        @redis.setex(@key, @ttl, block_result)
        block_result
      end
    else
      @redis.get(@key)
    end
  end
end
