require 'redis'
require 'hiredis'

class Redis
  HOST = ENV['REDIS_HOST']
  TTL = 3.days

  def used_memory
    info['used_memory_rss_human']
  end

  def used_memory_peak
    info['used_memory_peak_human']
  end

  class << self
    def client(host = nil)
      db = Rails.env.test? ? 1 : 0
      new(host: host || HOST, db: db, timeout: 3.0, driver: :hiredis)
    end
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
end
