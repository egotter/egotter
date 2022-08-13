class CreateDirectMessageEventLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    DirectMessageEventLog.create!(attrs)
  end
end
