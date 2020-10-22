class SearchRequest
  def initialize
    @store = ActiveSupport::Cache::RedisCacheStore.new(
        namespace: "#{Rails.env}:search_request",
        expires_in: 10.minutes,
        redis: Redis.client
    )
  end

  def exists?(screen_name)
    @store.exist?(screen_name)
  end

  def write(screen_name)
    @store.write(screen_name, true)
  end
end
