class ProcessStripeChargeFailedEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  #   event_id
  #   charge_id
  def perform(customer_id, options = {})
    orders = Order.where(customer_id: customer_id, canceled_at: nil, charge_failed_at: nil)
    props = {customer_id: customer_id, options: options}

    if orders.size == 0
      customer = Customer.latest_by(stripe_customer_id: customer_id)
      checkout_session = CheckoutSession.latest_by(user_id: customer.user_id)

      if checkout_session.valid_period?
        send_message('The customer probably failed to enter card details on the checkout page', props)
      else
        send_error_message('[To Be Fixed] Cannot find the order to be cancelled', props)
      end
    elsif orders.size == 1
      order = orders[0]
      props.merge!(user_id: order.user_id, order_id: order.id)

      order.update!(charge_failed_at: Time.zone.now)
      order.cancel!('webhook')
      send_message('Success', props)
    else
      props.merge!(order_ids: orders.map(&:id))
      send_error_message('[To Be Fixed] More than two orders are found', props)
    end
  rescue => e
    Airbag.exception e, customer_id: customer_id, options: options
  end

  private

  def send_message(message, props)
    SlackBotClient.channel('orders_charge_failed').post_message("`#{Rails.env}` #{message} #{props}")
  rescue => e
    Airbag.exception e, message: message, props: props
  end

  def send_error_message(message, props)
    send_message(message, props)
    SendMessageToSlackWorker.perform_async(:orders_warning, "#{message} type=charge.failed #{props}")
  end
end
