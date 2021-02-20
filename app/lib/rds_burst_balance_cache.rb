class RdsBurstBalanceCache
  def initialize
    @store = ActiveSupport::Cache::RedisCacheStore.new(
        namespace: "#{Rails.env}:#{self.class}",
        expires_in: 30.minutes,
        race_condition_ttl: 5.minutes,
        redis: self.class.redis
    )
  end

  def get
    @store.read('burst_balance') || 100.0
  end

  def update
    value = CloudWatchClient.new.get_rds_burst_balance
    @store.write('burst_balance', value)
  end

  def self.redis
    @redis ||= Redis.client(ENV['REDIS_HOST'])
  end
end
