class ProcessStripeChargeSucceededEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  def perform(customer_id, options = {})
    if (order = Order.order(created_at: :desc).find_by(customer_id: customer_id))
      order.charge_succeeded!
      send_message("Success user_id=#{order.user_id} order_id=#{order.id}")
    else
      send_message("Order not found customer_id=#{customer_id}")
    end
  rescue => e
    logger.warn "#{e.inspect} customer_id=#{customer_id}"
  end

  private

  def send_message(message)
    SlackBotClient.channel('orders_charge_succeeded').post_message("`#{Rails.env}` #{message}")
  rescue => e
    logger.warn "Failed #{e.inspect} message=#{message}"
  end
end
