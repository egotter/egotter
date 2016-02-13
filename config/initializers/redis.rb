Redis.class_eval do
  def fetch(key, ttl = 43200) # = 12.hours
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

  def self.job_dispatcher_added_key
    'update_job_dispatcher:recently_added'
  end

  def self.job_dispatcher_enqueue_num_key
    'update_job_dispatcher:enqueue_num'
  end

  def self.debug_info_key
    'update_job_dispatcher:debug'
  end

  def self.background_update_worker_too_many_friends_key
    'background_update_worker:too_many_friends'
  end

  def self.background_update_worker_unauthorized_key
    'background_update_worker:unauthorized'
  end

  # not using
  def self.background_update_worker_recently_failed_key
    'background_update_worker:recently_failed'
  end

  def clear_result_cache
    _keys = keys('searches:*')
    del(_keys) if _keys.any?
  end
end