# -*- SkipSchemaAnnotations
module InMemory
  TTL = 1.hour

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

  # 1 hour +(or -) 60 seconds
  def ttl_with_random
    TTL.send([:+, :-].shuffle[0], rand(60))
  end

  def cache_alive?(time)
    time > TTL.ago + 60.seconds
  end
end
