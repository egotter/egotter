class ProcessStripeChargeFailedEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  #   event_id
  #   charge_id
  def perform(customer_id, options = {})
    orders = Order.where(customer_id: customer_id, canceled_at: nil, charge_failed_at: nil)

    if orders.size == 1
      order = orders[0]
      props = {user_id: order.user_id, order_id: order.id, customer_id: customer_id, options: options}

      order.update!(charge_failed_at: Time.zone.now)
      order.cancel!('webhook')
      send_message('Success', props)
    else
      props = {customer_id: customer_id, options: options}

      begin
        customer = Customer.latest_by(stripe_customer_id: customer_id)
        checkout_session = CheckoutSession.latest_by(user_id: customer.user_id)

        if checkout_session.valid_period?
          send_error_message('Valid checkout session found', props)
        else
          send_error_message('Order can not be determined', props)
        end
      rescue => e
        Airbag.exception e, customer_id: customer_id, options: options
        send_error_message('Something error', props)
      end
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
