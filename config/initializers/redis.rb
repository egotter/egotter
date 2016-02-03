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

  def clear_result_cache
    del(keys('searches:*'))
  end
end