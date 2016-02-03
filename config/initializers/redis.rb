Redis.class_eval do
  def fetch(key, ttl = 1800) # 1800 seconds = 30 minutes
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

  def self.result_cache_key_prefix

  end

  def self.job_dispatcher_key
    'update_job_dispatcher:recently_added'
  end

  def self.debug_key
    'update_job_dispatcher:debug'
  end

  def self.background_update_worker_recently_failed_key
    'background_update_worker:recently_failed'
  end

  def clear_result_cache
    _keys = keys('searches:*')
    del(keys('searches:*')) if _keys.any?
  end
end