Redis.class_eval do
  def self.client
    new(host: ENV['REDIS_HOST'], driver: :hiredis)
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

  def self.search_controller_delay_occurs_count
    'search_controller:delay_occurs_count'
  end

  def self.search_controller_delay_does_not_occur_count
    'search_controller:delay_does_not_occur_count'
  end

  def delay_occurs_count
    get(self.class.search_controller_delay_occurs_count).to_i
  end

  def delay_occurs_rate
    delay_count = delay_occurs_count.to_f
    not_delay_count = get(self.class.search_controller_delay_does_not_occur_count).to_f
    delay_count / (delay_count + not_delay_count)
  rescue
    0.0
  end

  def incr_delay_occurs_count
    incr(self.class.search_controller_delay_occurs_count)
  end

  def incr_delay_does_not_occur_count
    incr(self.class.search_controller_delay_does_not_occur_count)
  end

  def del_delay_occurs_count
    del(self.class.search_controller_delay_occurs_count)
    del(self.class.search_controller_delay_does_not_occur_count)
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