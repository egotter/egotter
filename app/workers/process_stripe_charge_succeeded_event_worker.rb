class ProcessStripeChargeSucceededEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(customer_id, options = {})
    orders = Order.where(customer_id: customer_id, canceled_at: nil, charge_failed_at: nil)
    props = {customer_id: customer_id, options: options}

    if orders.size == 0
      send_error_message('[To Be Fixed] There is not a order for to be charged', props)
    elsif orders.size == 1
      user = orders[0].user
      props.merge!(user_id: user.id)

      if user.has_valid_subscription?
        send_message('Success', props)
      else
        send_error_message("[To Be Fixed] The customer doesn't have a valid subscription", props)
      end
    else
      props.merge!(order_ids: orders.map(&:id))
      send_error_message('[To Be Fixed] There are more than two orders for to be charged', props)
    end
  rescue => e
    Airbag.exception e, customer_id: customer_id, options: options
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
