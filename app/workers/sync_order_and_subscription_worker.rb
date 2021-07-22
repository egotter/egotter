# TODO Remove later
class SyncOrderAndSubscriptionWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    subscription = Stripe::Subscription.update(order.subscription_id, {metadata: {order_id: order.id}})
    order.trial_end = subscription.trial_end

    if (customer = order.fetch_stripe_customer) && !customer.email.nil?
      order.email = customer.email
    end

    order.save! if order.changed?
  rescue => e
    logger.warn "#{e.inspect} order_id=#{order_id} options=#{options.inspect}"
  end
end
