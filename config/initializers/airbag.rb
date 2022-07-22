Rails.application.reloader.to_prepare do
  Airbag.tag = Sidekiq.server? ? :sidekiq : :web

  Airbag.broadcast do |level, raw_message, message, props, ctx|
    if level > Logger::INFO
      channel = Rails.env.production? ? :airbag : :airbag_dev
      SendMessageToSlackWorker.perform_async(channel, message.truncate(1000))
    end
  rescue => e
  end

  Airbag.broadcast do |level, raw_message, message, props, ctx|
    (Sidekiq.server? ? Sidekiq : Rails).logger.add(level, "[airbag] #{raw_message}")
  rescue => e
  end
end
