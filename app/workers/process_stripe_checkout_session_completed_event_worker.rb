class ProcessStripeCheckoutSessionCompletedEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(checkout_session_id, options = {})
    checkout_session = Stripe::Checkout::Session.retrieve(checkout_session_id)

    unless (user = User.find_by(id: checkout_session.client_reference_id))
      send_error_message('[To Be Fixed] User not found', checkout_session_id)
      return
    end

    if user.has_valid_subscription?
      send_error_message('[To Be Fixed] User already has a subscription', checkout_session_id, user_id: user.id)
      return
    end

    if checkout_session.mode == 'payment'
      order = Order.create_by_monthly_basis(checkout_session)
    else
      order = Order.create_by_checkout_session(checkout_session)
    end

    update_trial_end_and_email(order)

    send_message('Success', checkout_session_id, user_id: user.id, order_id: order.id, order_name: order.name)
  rescue => e
    Airbag.exception e, checkout_session_id: checkout_session_id
    send_error_message('[To Be Fixed] A fatal error occurred', checkout_session_id)
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

  def send_message(message, checkout_session_id, props = {})
    SlackBotClient.channel('orders_cs_completed').post_message("`#{Rails.env}` #{message} #{checkout_session_id} #{props}")
  rescue => e
    Airbag.exception e, message: message, checkout_session_id: checkout_session_id, props: props
  end

  def send_error_message(message, checkout_session_id, props = {})
    send_message(message, checkout_session_id, props)
    SendMessageToSlackWorker.perform_async(:orders_warning, "#{message} #{checkout_session_id} type=checkout.session.completed #{props}")
  rescue => e
    Airbag.exception e, message: message, checkout_session_id: checkout_session_id, props: props
  end
end
