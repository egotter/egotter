Sidekiq.logger.level = Logger::DEBUG

database = Rails.env.test? ? 1 : 0

Sidekiq.configure_server do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379/#{database}"}
  config.server_middleware do |chain|
    chain.add UniqueJob::ServerMiddleware
    chain.add ExpireJob::Middleware
    chain.add TimeoutJob::Middleware
  end
  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379/#{database}"}
  config.client_middleware do |chain|
    chain.add UniqueJob::ClientMiddleware
  end
end
