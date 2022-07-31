Sidekiq.strict_args!(false)

database = Rails.env.test? ? 1 : 0
redis_options = {
    host: ENV['REDIS_HOST'],
    db: 5,
    connect_timeout: 0.2,
    read_timeout: 1.0,
    write_timeout: 0.5,
    driver: :hiredis
}

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 20, timeout: 1) { Redis.new(host: ENV['REDIS_HOST'], db: database) }

  config.server_middleware do |chain|
    chain.add UniqueJob::ServerMiddleware, redis_options
    chain.add ExpireJob::Middleware
  end

  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware, redis_options
  end

  config.error_handlers << Proc.new do |e, context|
    Airbag.exception e, location: 'Sidekiq.error_handler', context: context
  rescue => ee
    Sidekiq.logger.error "Sidekiq.error_handler: #{ee.inspect} context=#{context}"
    Sidekiq.logger.error "Sidekiq.error_handler: #{ee.backtrace.join("\n")}"
    if ee.cause
      Sidekiq.logger.error "Sidekiq.error_handler: cause: #{ee.cause.inspect}"
      Sidekiq.logger.error "Sidekiq.error_handler: cause: #{ee.cause.backtrace.join("\n")}"
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 10, timeout: 1) { Redis.new(host: ENV['REDIS_HOST'], db: database) }

  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware, redis_options
  end
end
