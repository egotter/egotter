class CreateStripeWebhookLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    Rails.logger.silence { StripeWebhookLog.create!(attrs) }
  rescue => e
    Airbag.warn "#{self.class}: #{e.class} #{e.message} #{attrs.inspect}"
  end
end
