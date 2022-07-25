class RedisClient < Redis
  HOST = ENV['REDIS_HOST']
  CONNECT_TIMEOUT = 0.2
  READ_TIMEOUT = 1.0
  WRITE_TIMEOUT = 0.5

  def initialize(opt = {})
    options = {
        host: HOST,
        db: (Rails.env.test? ? 1 : 0),
        connect_timeout: CONNECT_TIMEOUT,
        read_timeout: READ_TIMEOUT,
        write_timeout: WRITE_TIMEOUT,
        driver: :hiredis
    }.merge(opt)

    if Rails.env.development?
      Airbag.debug 'Initialize RedisClient', options: options, location: caller[0]
    end

    super(options)
  end
end
