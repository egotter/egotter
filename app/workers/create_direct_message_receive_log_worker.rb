class CreateDirectMessageReceiveLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    attrs.stringify_keys! # This worker could be run synchronously
    attrs['automated'] = !!attrs['message']&.include?('#egotter')
    DirectMessageReceiveLog.create!(attrs)
  end
end
