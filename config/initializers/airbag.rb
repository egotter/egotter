Rails.application.reloader.to_prepare do
  if Sidekiq.server?
    Airbag.broadcast(target: :slack, channel: :airbag, tag: 'sidekiq', level: Logger::INFO)
    Airbag.logger.extend ActiveSupport::Logger.broadcast(Sidekiq.logger)
  else
    Airbag.broadcast(target: :slack, channel: :airbag, tag: 'web', level: Logger::INFO)
    Airbag.logger.extend ActiveSupport::Logger.broadcast(Rails.logger)
  end
end
