class CreateDirectMessageSendLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(attrs, options = {})
    attrs['automated'] = attrs['message']&.include?('#egotter')
    DirectMessageSendLog.create!(attrs)
  end
end
