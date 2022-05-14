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
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379/#{database}"}
  config.server_middleware do |chain|
    chain.add UniqueJob::ServerMiddleware, redis_options
    chain.add ExpireJob::Middleware
    chain.add TimeoutJob::Middleware
    chain.add Egotter::Sidekiq::LockJob
  end
  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware, redis_options
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379/#{database}"}
  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware, redis_options
  end
end
