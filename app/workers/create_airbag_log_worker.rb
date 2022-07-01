class CreateAirbagLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(severity, message, properties = nil, time = nil)
    AirbagLog.create!(severity: severity, message: message, properties: properties, time: time || Time.zone.now)
  rescue => e
    logger.warn "#{self.class}: severity=#{severity} message=#{message} properties=#{properties} time=#{time} #{e.inspect}"
  end
end
