class PeriodicReportReportableFlag
  class << self
    def on(user_id, period)
      store.write(key(user_id, period), 1)
    end

    def on?(user_id, period)
      store.exist?(key(user_id, period))
    end

    # TODO Remove later
    def create(user_id:)
      store.write("reportable:#{user_id}", 1)
    end

    # TODO Remove later
    def exists?(user_id:)
      store.exist?("reportable:#{user_id}")
    end

    # For debug
    def keys
      store.redis.keys("#{Rails.env}:#{self}:reportable:*")
    end

    # For debug
    def size
      keys.size
    end

    private

    def key(user_id, period)
      "reportable:#{user_id}:#{date}:#{period}"
    end

    def date
      Time.zone.now.in_time_zone('Tokyo').strftime('%Y%m%d')
    end

    def store
      @store ||= ActiveSupport::Cache::RedisCacheStore.new(
          namespace: "#{Rails.env}:#{self}",
          expires_in: 3.hours,
          redis: RedisClient.new(host: ENV['REDIS_HOST'], db: 4)
      )
    end
  end
end
