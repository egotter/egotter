require 'redis'
require 'hiredis'

class Redis
  HOST = ENV['REDIS_HOST']
  TTL = 3.days
  CONNECT_TIMEOUT = 0.2
  READ_TIMEOUT = 1.0
  WRITE_TIMEOUT = 0.5

  class << self
    def client(host = nil, options = {})
      options = {
          host: (host || HOST),
          db: (Rails.env.test? ? 1 : 0),
          connect_timeout: CONNECT_TIMEOUT,
          read_timeout: READ_TIMEOUT,
          write_timeout: WRITE_TIMEOUT,
          driver: :hiredis
      }.merge(options)

      Rails.logger.debug { "Initialize Redis options=#{options}" }

      new(options)
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
