class ProcessStripeChargeSucceededEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(customer_id, options = {})
    orders = Order.where(customer_id: customer_id)

    if orders.size >= 1
      user = orders[0].user
      props = {user_id: user.id, customer_id: customer_id}

      if user.has_valid_subscription?
        send_message('Success', props)
      else
        send_error_message("User doesn't have a valid subscription", props)
      end
    else
      props = {customer_id: customer_id}
      send_error_message('Order not found', props)
    end
  rescue => e
    Airbag.exception e, customer_id: customer_id
  end

  private

  def send_message(message, props)
    SlackBotClient.channel('orders_charge_succeeded').post_message("`#{Rails.env}` #{message} #{props}")
  rescue => e
    Airbag.exception e, message: message, props: props
  end

  def send_error_message(message, props)
    send_message(message, props)
    SendMessageToSlackWorker.perform_async(:orders_warning, "#{message} type=charge.succeeded #{props}")
  end
end
