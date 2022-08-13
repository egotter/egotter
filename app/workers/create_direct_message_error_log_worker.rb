class CreateDirectMessageErrorLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    DirectMessageErrorLog.create!(attrs)
  end
end
