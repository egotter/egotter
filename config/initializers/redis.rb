Redis.class_eval do
  def self.client
    self.new(host: ENV['REDIS_HOST'], driver: :hiredis)
  end

  DEFAULT_EGOTTER_CACHE_TTL = Rails.configuration.x.constants['result_cache_ttl']

  def fetch(key, ttl = DEFAULT_EGOTTER_CACHE_TTL)
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

  def self.foreground_search_searched_uids_key
    'background_search_worker:searched_uids'
  end

  def rem_unauthorized_uid(uid)
    zrem(self.class.background_update_worker_unauthorized_key, uid.to_s)
  end

  def rem_too_many_friends_uid(uid)
    zrem(self.class.background_update_worker_too_many_friends_key, uid.to_s)
  end

  def rem_searched_uid(uid)
    zrem(self.class.foreground_search_searched_uids_key, uid.to_s)
  end

  def clear_result_cache
    _keys = keys('searches:*')
    del(_keys) if _keys.any?
  end

  def clear_searched_uid
    del(self.class.foreground_search_searched_uids_key)
  end
end