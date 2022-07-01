Rails.application.reloader.to_prepare do

  if Sidekiq.server?
    Airbag.broadcast(target: :slack, channel: :airbag, tag: 'sidekiq')
    Airbag.logger.extend ActiveSupport::Logger.broadcast(Sidekiq.logger)
  else
    Airbag.broadcast(target: :slack, channel: :airbag, tag: 'web')
    Airbag.logger.extend ActiveSupport::Logger.broadcast(Rails.logger)
  end
end
