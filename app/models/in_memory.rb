# -*- SkipSchemaAnnotations
module InMemory
  TTL = 5.minutes

  module_function

  def redis_hostname
    ENV['IN_MEMORY_REDIS_HOST']
  end

  def used_memory
    Redis.client(redis_hostname).info['used_memory_rss_human']
  end

  def used_memory_peak
    Redis.client(redis_hostname).info['used_memory_peak']
  end

  def enabled?
    ENV['DISABLE_IN_MEMORY_RESOURCES'] != '1'
  end

  def cache_alive?(time)
    time > TTL.ago
  end
end
