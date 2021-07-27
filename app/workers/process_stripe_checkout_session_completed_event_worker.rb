class ProcessStripeCheckoutSessionCompletedEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(checkout_session_id, options = {})
    checkout_session = Stripe::Checkout::Session.retrieve(checkout_session_id)

    unless (user = User.find_by(id: checkout_session.client_reference_id))
      send_message("User not found checkout_session_id=#{checkout_session_id}")
      return
    end

    if user.has_valid_subscription?
      send_message("User already has a subscription user_id=#{user.id} checkout_session_id=#{checkout_session_id}")
      return
    end

    order = Order.create_by_checkout_session(checkout_session)
    update_trial_end_and_email(order)

    send_message("Success user_id=#{user.id} order_id=#{order.id}")
  rescue => e
    logger.warn "#{e.inspect} checkout_session_id=#{checkout_session_id}"
  end

  private

  def update_trial_end_and_email(order)
    subscription = Stripe::Subscription.update(order.subscription_id, {metadata: {order_id: order.id}})
    order.trial_end = subscription.trial_end

    if (customer = Stripe::Customer.retrieve(order.customer_id)) && customer.email
      order.email = customer.email
    end

    order.save if order.changed?
  end

  def send_message(message)
    SlackMessage.create(channel: 'orders_cs_completed', message: message)
    SlackBotClient.channel('orders_cs_completed').post_message("`#{Rails.env}` #{message}")
  rescue => e
    logger.warn "##{__method__} failed #{e.inspect} message=#{message}"
  end
end
