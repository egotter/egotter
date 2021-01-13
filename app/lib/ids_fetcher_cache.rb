class IdsFetcherCache
  def initialize(klass)
    @store = ActiveSupport::Cache::RedisCacheStore.new(
        namespace: "#{Rails.env}:#{klass}",
        expires_in: 10.minutes,
        redis: self.class.redis
    )
  end

  def read(uid, cursor)
    if (data = @store.read(cache_key(uid, cursor)))
      JSON.parse(data)
    end
  end

  def write(uid, cursor, data)
    @store.write(cache_key(uid, cursor), data.to_json)
  end

  def cache_key(uid, cursor)
    "uid:#{uid}:cursor:#{cursor}"
  end

  def self.redis
    @redis ||= Redis.client(ENV['REDIS_HOST'], db: 3)
  end
end
