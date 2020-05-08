# -*- SkipSchemaAnnotations
module InMemory
  module_function

  def redis_hostname
    ENV['IN_MEMORY_REDIS_HOST']
  end

  def used_memory
    Redis.client(redis_hostname).info['used_memory_rss_human']
  end
end
