Redis.class_eval do
  HOST = ENV['REDIS_HOST']
  TTL = 3.days

  def self.client
    new(host: HOST, driver: :hiredis)
  end

  def fetch(key, ttl: TTL)
    if block_given?
      if exists(key)
        get(key)
      else
        block_result = yield
        setex(key, ttl, block_result)
        block_result
      end
    else
      get(key)
    end
  end

  def self.debug_info_key
    'update_job_dispatcher:debug'
  end
end