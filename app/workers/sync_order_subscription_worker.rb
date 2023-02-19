# TODO Remove later
class SyncOrderSubscriptionWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc_low', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    order = Order.find(order_id)

    if order.canceled_at
      send_message('already canceled', order, 'none')
      return
    end

    if (subscription = fetch_subscription(order.subscription_id))
      cancel_order(order, subscription)
      # end_trial_period(order, subscription)
    else
      send_message('subscription not found', order, 'none')
    end
  rescue => e
    Airbag.exception e, order_id: order_id, options: options
  end

  private

  def fetch_subscription(subscription_id)
    subscription_id && Stripe::Subscription.retrieve(subscription_id)
  end

  def cancel_order(order, subscription)
    if (timestamp = subscription.canceled_at) && order.canceled_at.nil?
      SendMessageToSlackWorker.perform_async(:orders_z_error, "Order to be deleted order_id=#{order.id} subscription_id=#{subscription.id}")
      # order.assign_attributes(canceled_at: Time.zone.at(timestamp))
      # if order.changed?
      #   order.save!
      #   send_message('cancel_order', order, order.saved_changes)
      # else
      #   send_message('cancel_order', order, 'none')
      # end
    end
  end

  def end_trial_period(order, subscription)
    if !order.trial_end && (trial_end = subscription.trial_end)
      order.assign_attributes(trial_end: trial_end)
      if order.changed?
        order.save!
        send_message('end_trial_period', order, order.saved_changes)
      else
        send_message('end_trial_period', order, 'none')
      end
    end
  end

  def send_message(reason, order, changes)
    message = "#{self.class}: reason=#{reason} order_id=#{order.id} user_id=#{order.user_id} subscription_id=#{order.subscription_id} changes=#{changes}"
    SlackBotClient.channel(:orders_sync).post_message(message)
  end
end
