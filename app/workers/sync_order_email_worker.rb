class SyncOrderEmailWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc_low', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    if !order.email && (email = fetch_customer_email(order.customer_id))
      order.update!(email: email)
      send_message(order)
    end
  rescue => e
    handle_worker_error(e, order_id: order_id, options: options)
  end

  private

  def fetch_customer_email(customer_id)
    customer_id && (customer = Stripe::Customer.retrieve(customer_id)) && customer.email
  end

  def send_message(order, channel = 'orders_sync')
    message = "#{self.class}: #{order.id} #{order.saved_changes.except('updated_at')}"
    SlackMessage.create(channel: channel, message: message)
    SlackBotClient.channel(channel).post_message(message)
  end
end
