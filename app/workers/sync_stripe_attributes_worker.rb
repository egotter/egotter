class SyncStripeAttributesWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    if (changes = order.sync_stripe_attributes!)
      send_message(order_id, changes)
    end
  rescue => e
    handle_worker_error(e, order_id: order_id, options: options)
  end

  private

  def send_message(order_id, changes)
    message = "#{order_id} #{changes}"
    SlackMessage.create(channel: 'orders_sync', message: message)
    SlackBotClient.channel('orders_sync').post_message("`#{Rails.env}` #{message}")
  end
end
