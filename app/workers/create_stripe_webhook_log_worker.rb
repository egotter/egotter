class CreateStripeWebhookLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    StripeWebhookLog.create!(attrs)
  end
end
