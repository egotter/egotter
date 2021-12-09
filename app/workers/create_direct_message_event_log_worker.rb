class CreateDirectMessageEventLogWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    DirectMessageEventLog.create!(attrs)
  rescue => e
    handle_worker_error(e, attrs: attrs, **options)
  end
end