class CreateDirectMessageReceiveLogWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    attrs.stringify_keys! # This worker could be run synchronously
    attrs['automated'] = !!attrs['message']&.include?('#egotter')
    DirectMessageReceiveLog.create!(attrs)
  rescue => e
    handle_worker_error(e, attrs: attrs, **options)
  end
end
