class CreateAirbagLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  KEYS = %w(backtrace cause_backtrace caller)

  def perform(severity, message, properties, time)
    AirbagLog.create!(severity: severity, message: message, properties: properties, time: time)
  rescue => e
    logger.error "#{e.inspect.truncate(1000)} severity=#{severity} message=#{message.truncate(1000)} properties=#{properties.except(*KEYS)} time=#{time}"
  end
end
