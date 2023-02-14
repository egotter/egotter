class ProcessStripeCheckoutSessionCompletedEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(checkout_session_id, options = {})
    user = order = nil
    checkout_session = Stripe::Checkout::Session.retrieve(checkout_session_id)

    unless (user = User.find_by(id: checkout_session.client_reference_id))
      send_message(:orders_cs_failed, 'User not found', checkout_session_id)
      return
    end

    if user.has_valid_subscription?
      send_message(:orders_cs_failed, 'User already has a subscription', checkout_session_id, user_id: user.id)
      return
    end

    if checkout_session.mode == 'payment'
      order = Order.create_by_monthly_basis(checkout_session)
    else
      order = Order.create_by_checkout_session(checkout_session)
    end

    update_trial_end_and_email(order)

    send_message(:orders_cs_completed, '', checkout_session_id, user_id: user.id, order_id: order.id, order_name: order.name)
  rescue => e
    Airbag.exception e, checkout_session_id: checkout_session_id
    send_message(:orders_cs_failed, e.inspect, checkout_session_id, user_id: user&.id, order_id: order&.id)
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

  def send_message(channel, msg, checkout_session_id, options = {})
    message = "#{msg} #{checkout_session_id} #{options}"
    SlackMessage.create(channel: channel, message: message)
    SlackBotClient.channel(channel).post_message("`#{Rails.env}` #{message}")
  rescue => e
    Airbag.warn "##{__method__} failed #{e.inspect} message=#{message}"
  end
end
