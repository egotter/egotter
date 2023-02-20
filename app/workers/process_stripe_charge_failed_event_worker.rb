class ProcessStripeChargeFailedEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(customer_id, options = {})
    orders = Order.select(:id, :user_id, :charge_failed_at).where(customer_id: customer_id, canceled_at: nil, charge_failed_at: nil)

    if orders.size == 1
      order = orders[0]
      props = {user_id: order.user_id, order_id: order.id, customer_id: customer_id}

      order.update!(charge_failed_at: Time.zone.now)
      order.cancel!('webhook')
      send_message("Success #{props}")
    else
      props = {customer_id: customer_id}
      send_message("Order can not be determined #{props}")
      SendMessageToSlackWorker.perform_async(:orders_warning, "Order can not be determined type=charge.failed #{props}")
    end
  rescue => e
    Airbag.exception e, customer_id: customer_id
  end

  private

  def send_message(message)
    SlackBotClient.channel('orders_charge_failed').post_message("`#{Rails.env}` #{message}")
  rescue => e
    Airbag.exception e, message: message
  end
end
