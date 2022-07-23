Rails.application.reloader.to_prepare do
  Airbag.tag = Sidekiq.server? ? 'sidekiq' : 'web'

  Airbag.broadcast do |level, message, props, ctx|
    if level > Logger::INFO
      channel = Rails.env.production? ? :airbag : :airbag_dev
      message = "#{Airbag.format_hash(ctx)} #{Airbag.format_severity(level)}: #{message.truncate(1000)} #{Airbag.format_hash(props)}"
      SendMessageToSlackWorker.perform_async(channel, message)
    end
  rescue => e
  end

  Airbag.broadcast do |level, message, props, ctx|
    (Sidekiq.server? ? Sidekiq : Rails).logger.add(level, "[airbag] #{message} #{Airbag.format_hash(props)}")
  rescue => e
  end
end
