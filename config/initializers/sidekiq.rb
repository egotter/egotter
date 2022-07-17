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

error_handler = Proc.new do |e, context|
  if (job = context[:job])
    message = "class=#{job['class']} args=#{job['args']}"
  else
    message = "context=#{context}"
  end
  Airbag.error "[ERROR HANDLER] #{e.inspect.truncate(200)} #{message}", backtrace: e.backtrace
rescue => ee
  Sidekiq.logger.error "[ERROR HANDLER] original=#{e.inspect.truncate(200)} current=#{ee.inspect.truncate(200)} context=#{context}"
end

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 20, timeout: 1) { Redis.new(host: ENV['REDIS_HOST'], db: database) }

  config.server_middleware do |chain|
    chain.add UniqueJob::ServerMiddleware, redis_options
    chain.add ExpireJob::Middleware
    chain.add TimeoutJob::Middleware
  end

  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware, redis_options
  end

  config.error_handlers << error_handler
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 10, timeout: 1) { Redis.new(host: ENV['REDIS_HOST'], db: database) }

  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware, redis_options
  end
end
