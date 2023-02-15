class ProcessStripeChargeSucceededEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(customer_id, options = {})
    orders = Order.select(:id, :user_id).where(customer_id: customer_id)

    if orders.size >= 1
      user = orders[0].user
      props = {user_id: user.id, customer_id: customer_id}

      if user.has_valid_subscription?
        send_message("Success #{props}")
      else
        send_message("User doesn't have a valid subscription #{props}")
        SendMessageToSlackWorker.perform_async(:orders_warning, "User doesn't have a valid subscription type=charge.succeeded #{props}")
      end
    else
      props = {customer_id: customer_id}
      send_message("Order not found #{props}")
      SendMessageToSlackWorker.perform_async(:orders_warning, "Order not found type=charge.succeeded #{props}")
    end
  rescue => e
    Airbag.exception e, customer_id: customer_id
  end

  private

  def send_message(message)
    SlackMessage.create(channel: 'orders_charge_succeeded', message: message)
    SlackBotClient.channel('orders_charge_succeeded').post_message("`#{Rails.env}` #{message}")
  rescue => e
    Airbag.warn "##{__method__} failed #{e.inspect} message=#{message}"
  end
end
