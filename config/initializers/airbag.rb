Rails.application.reloader.to_prepare do
  Airbag.tags = {name: ENV['AWS_NAME_TAG'], role: Sidekiq.server? ? 'sidekiq' : 'web'}

  Airbag.broadcast do |level, message, props, ctx|
    if level >= Logger::INFO
      CreateAirbagLogWorker.perform_async(
          Airbag.format_severity(level), message.to_s.truncate(50000), Airbag.truncate_hash(ctx.merge(props)), Time.zone.now)
    end
  rescue => e
    Rails.logger.error "CreateAirbagLogWorker: #{e.inspect}"
    Rails.logger.error e.backtrace.join("\n")
  end

  Airbag.broadcast do |level, message, props, ctx|
    if level >= Logger::WARN
      message = "#{Airbag.format_hash(ctx)} #{Airbag.format_severity(level)}: #{message.truncate(1000)} #{Airbag.format_hash(props)}"
      SendAirbagMessageToSlackWorker.perform_in(10, message)
    end
  rescue => e
    Rails.logger.error "initializers/airbag.rb: target=slack #{e.inspect}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # Airbag.broadcast do |level, message, props, ctx|
  #   (Sidekiq.server? ? Sidekiq : Rails).logger.add(level, "[airbag] #{message} #{Airbag.format_hash(props)}")
  # rescue => e
  #   Rails.logger.error "initializers/airbag.rb: target=file #{e.inspect}"
  #   Rails.logger.error e.backtrace.join("\n")
  # end
end
