Sidekiq::Logging.logger.level = Logger::DEBUG

Sidekiq.configure_server do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379"}
  config.server_middleware do |chain|
    chain.add Egotter::Sidekiq::ServerUniqueJob
    chain.add Egotter::Sidekiq::ExpireJob
    chain.add Egotter::Sidekiq::TimeoutJob
  end
  config.client_middleware do |chain|
    chain.add Egotter::Sidekiq::ClientUniqueJob, 'server'
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379"}
  config.client_middleware do |chain|
    chain.add Egotter::Sidekiq::ClientUniqueJob, 'client'
  end
end
