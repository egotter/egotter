class CreateStripeWebhookLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    StripeWebhookLog.create!(attrs)
  rescue => e
    Airbag.error "#{e.inspect} attrs=#{attrs}", backtrace: e.backtrace
  end
end
