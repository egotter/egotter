# -*- SkipSchemaAnnotations
module InMemory
  TTL = 10.minutes

  module_function

  def redis_hostname
    ENV['IN_MEMORY_REDIS_HOST']
  end

  def redis_instance
    Redis.client(redis_hostname)
  end

  def enabled?
    ENV['DISABLE_IN_MEMORY_RESOURCES'] != '1'
  end

  def cache_alive?(time)
    time > TTL.ago
  end
end
