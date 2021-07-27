class ProcessStripePaymentIntentSucceededEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(stripe_payment_intent_id, options = {})
    stripe_payment_intent = Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
    return unless StripePaymentIntent.intent_for_bank_transfer?(stripe_payment_intent)

    unless (payment_intent = PaymentIntent.find_by(stripe_payment_intent_id: stripe_payment_intent_id))
      send_message("PaymentIntent not found stripe_payment_intent_id=#{stripe_payment_intent_id}")
      return
    end

    create_order(stripe_payment_intent, payment_intent)
  rescue => e
    logger.warn "#{e.inspect} stripe_payment_intent_id=#{stripe_payment_intent_id}"
  end

  private

  def create_order(stripe_payment_intent, payment_intent)
    user = payment_intent.user
    stripe_customer = Stripe::Customer.retrieve(stripe_payment_intent.customer)

    if user.has_valid_subscription?
      send_message("User already have a subscription user_id=#{user.id}")
    else
      order = Order.create_by_bank_transfer(user, stripe_customer)
      payment_intent.update(succeeded_at: Time.zone.now)
      send_message("Success user_id=#{user.id} order_id=#{order.id}")
    end
  end

  def send_message(message)
    SlackMessage.create(channel: 'orders_pi_succeeded', message: message)
    SlackBotClient.channel('orders_pi_succeeded').post_message("`#{Rails.env}` #{message}")
  rescue => e
    logger.warn "Failed #{e.inspect} message=#{message}"
  end
end
