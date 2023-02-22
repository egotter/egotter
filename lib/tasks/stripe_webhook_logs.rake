namespace :stripe_webhook_logs do
  task verify: :environment do
    keys = StripeWebhookLog.where('created_at > ?', 24.hours.ago).pluck(:idempotency_key)
    unless keys.size == keys.uniq.size
      result = keys.tally.select { |k, v| v != 1 }
      puts "Invalid data #{result}"
    end
  end
end
