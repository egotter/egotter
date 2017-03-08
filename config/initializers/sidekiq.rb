Sidekiq::Logging.logger.level = Logger::DEBUG

Sidekiq.configure_server do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379"}
end

Sidekiq.configure_client do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379"}
end