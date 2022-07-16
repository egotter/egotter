class SyncOrderSubscriptionWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc_low', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    if (subscription = fetch_subscription(order.subscription_id))
      cancel_order(order, subscription)
      end_trial_period(order, subscription)
    end
  rescue => e
    handle_worker_error(e, order_id: order_id, options: options)
  end

  private

  def fetch_subscription(subscription_id)
    subscription_id && Stripe::Subscription.retrieve(subscription_id)
  end

  def cancel_order(order, subscription)
    if (timestamp = subscription.canceled_at)
      order.update!(canceled_at: Time.zone.at(timestamp))
      send_message(order, 'cancel_order')
    end
  end

  def end_trial_period(order, subscription)
    if !order.trial_end && (trial_end = subscription.trial_end)
      order.update!(trial_end: trial_end)
      send_message(order, 'end_trial_period')
    end
  end

  def send_message(order, location)
    channel = 'orders_sync'
    message = "#{self.class}: location=#{location} order_id=#{order.id} #{order.saved_changes}"
    SlackMessage.create(channel: channel, message: message)
    SlackBotClient.channel(channel).post_message(message)
  end
end
