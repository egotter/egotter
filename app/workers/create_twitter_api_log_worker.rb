class CreateTwitterApiLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    TwitterApiLog.create!(attrs)
  rescue ActiveRecord::StatementInvalid => e
    Airbag.warn e.inspect, attrs: attrs
  rescue => e
    Airbag.exception e, attrs: attrs
  end
end
