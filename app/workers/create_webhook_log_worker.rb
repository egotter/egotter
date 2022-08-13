class CreateWebhookLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    WebhookLog.create!(attrs)
  end
end
