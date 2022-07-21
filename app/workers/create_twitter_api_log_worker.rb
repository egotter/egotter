class CreateTwitterApiLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    TwitterApiLog.create!(attrs)
  rescue => e
    Airbag.exception e, attrs: attrs
  end
end
