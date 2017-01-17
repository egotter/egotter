class CreatePollingLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(attrs)
    PollingLog.create!(attrs)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end
end
