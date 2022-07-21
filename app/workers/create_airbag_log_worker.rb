class CreateAirbagLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(severity, message, properties = nil, time = nil)
    AirbagLog.create!(severity: severity, message: message, properties: properties.presence, time: time || Time.zone.now)
  rescue => e
    logger.error "#{e.inspect.truncate(1000)} severity=#{severity} message=#{message.truncate(1000)} properties=#{properties} time=#{time}"
  end
end
