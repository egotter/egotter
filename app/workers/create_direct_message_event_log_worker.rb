class CreateDirectMessageEventLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    DirectMessageEventLog.create!(attrs)
  rescue => e
    Airbag.exception e, attrs: attrs, options: options
  end
end
