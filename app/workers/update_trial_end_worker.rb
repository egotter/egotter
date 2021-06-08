class UpdateTrialEndWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)
    order.sync_trial_end!
    order.update!(email: order.fetch_stripe_customer.email)
  rescue => e
    logger.warn "#{e.inspect} order_id=#{order_id} options=#{options.inspect}"
  end
end
