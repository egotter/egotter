class PeriodicReportReportableFlag
  class << self
    def create(user_id:)
      store.write("reportable:#{user_id}", 1)
    end

    def exists?(user_id:)
      store.exist?("reportable:#{user_id}")
    end

    private

    def store
      @store ||= ActiveSupport::Cache::RedisCacheStore.new(
          namespace: "#{Rails.env}:#{self}",
          expires_in: 3.hours,
          redis: Redis.client(ENV['REDIS_HOST'], db: 4)
      )
    end
  end
end
