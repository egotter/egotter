class RedisStats
  def initialize
    @stats = [
        Redis.client,
        InMemory,
        ApiClient::CacheStore.redis_client
    ].map { |obj| [obj, obj.used_memory_peak] }
  end

  def to_s
    @stats.map do |name, value|
      "#{name} #{value}"
    end.join("\n")
  end
end
