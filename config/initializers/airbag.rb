Rails.application.reloader.to_prepare do
  logger = Sidekiq.server? ? Sidekiq.logger : Rails.logger
  Airbag.logger.extend ActiveSupport::Logger.broadcast(logger)
end
