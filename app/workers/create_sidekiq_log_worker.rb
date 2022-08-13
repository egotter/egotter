class CreateSidekiqLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(severity, message, properties, time)
    SidekiqLog.create!(message: message, properties: properties, time: time)
  end
end
