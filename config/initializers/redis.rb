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
      host = host || HOST
      db = Rails.env.test? ? 1 : 0

      new(host: host, db: db, connect_timeout: 0.2, read_timeout: 1.0, write_timeout: 0.5, driver: :hiredis)
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
