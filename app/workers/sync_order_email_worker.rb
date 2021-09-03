class SyncOrderEmailWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc_low', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    if (new_email = fetch_customer_email(order.customer_id)) && order.email != new_email
      order.update!(email: new_email)
      send_message(order_id, order.saved_change_to_email)
    end
  rescue => e
    handle_worker_error(e, order_id: order_id, options: options)
  end

  private

  def fetch_customer_email(customer_id)
    customer_id && (customer = Stripe::Customer.retrieve(customer_id)) && customer.email
  end

  def send_message(order_id, changes, channel = 'orders_sync')
    message = "#{order_id} #{changes}"
    SlackMessage.create(channel: channel, message: message)
    SlackBotClient.channel(channel).post_message("`#{Rails.env}` #{message}")
  end
end
