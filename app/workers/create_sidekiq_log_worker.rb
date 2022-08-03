class CreateSidekiqLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(severity, message, properties, time)
    SidekiqLog.create!(message: message, properties: properties, time: time)
  rescue ActiveRecord::StatementInvalid => e
    Airbag.warn e.inspect, attrs: attrs
  rescue => e
    Airbag.exception e, message: message, properties: properties, time: time
  end
end
