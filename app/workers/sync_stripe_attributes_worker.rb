class SyncStripeAttributesWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    if (changes = order.sync_stripe_attributes!)
      SlackClient.channel('orders_sync').send_message("`#{Rails.env}:sync` #{order_id} #{changes}")
    end
  rescue => e
    handle_worker_error(e, order_id: order_id, options: options)
  end
end
