class SyncOrderSubscriptionWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc_low', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    if (subscription = fetch_subscription(order.subscription_id))
      update_canceled_at(order, subscription)
      update_trial_end(order, subscription)
    end
  rescue => e
    handle_worker_error(e, order_id: order_id, options: options)
  end

  private

  def fetch_subscription(subscription_id)
    subscription_id && Stripe::Subscription.retrieve(subscription_id)
  end

  def update_canceled_at(order, subscription)
    if (timestamp = subscription.canceled_at)
      order.update!(canceled_at: Time.zone.at(timestamp))
      send_message(order.id, order.saved_change_to_canceled_at)
    end
  end

  def update_trial_end(order, subscription)
    if !order.trial_end && (trial_end = subscription.trial_end)
      order.update!(trial_end: trial_end)
      send_message(order.id, order.saved_change_to_trial_end)
    end
  end

  def send_message(order_id, changes, channel = 'orders_sync')
    message = "#{order_id} #{changes}"
    SlackMessage.create(channel: channel, message: message)
    SlackBotClient.channel(channel).post_message("`#{Rails.env}` #{message}")
  end
end
