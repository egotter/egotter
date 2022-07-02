class CreateSidekiqLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(message, properties = nil, time = nil)
    SidekiqLog.create!(message: message, properties: properties, time: time || Time.zone.now)
  rescue => e
    logger.warn "#{self.class}: message=#{message} properties=#{properties} time=#{time} #{e.inspect}"
  end
end
