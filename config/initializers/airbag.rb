Rails.application.reloader.to_prepare do
  if Sidekiq.server?
    Airbag.broadcast(target: :slack, channel: :airbag, tag: 'sidekiq', level: Logger::INFO)
    Airbag.broadcast(target: :logger, instance: Sidekiq.logger)
  else
    Airbag.broadcast(target: :slack, channel: :airbag, tag: 'web', level: Logger::INFO)
    Airbag.broadcast(target: :logger, instance: Rails.logger)
  end
end
