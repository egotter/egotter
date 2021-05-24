namespace :orders do
  desc 'Update stripe attributes'
  task update_stripe_attributes: :environment do
    Order.where(canceled_at: nil).find_each do |order|
      SyncStripeAttributesWorker.perform_async(order.id)
    end
  end

  desc 'update trial_end'
  task update_trial_end: :environment do
    Order.find_each do |order|
      if order.trial_end.nil?
        sub = order.stripe_subscription
        order.update(trial_end: sub.trial_end)
      end
    end
  end

  desc 'Invalidate insufficient subscriptions'
  task invalidate_insufficient_subscriptions: :environment do
    Order.unexpired.find_each do |order|
      unless order.stripe_customer.invoices[0].paid
        order.cancel!
      end
    end
  end

  task create: :environment do
    user = ENV['USER_ID'] ? User.find(ENV['USER_ID']) : User.find_by(screen_name: ENV['SCREEN_NAME'])
    ActivateSubscriptionTask.new(
        user,
        ENV['MONTHS_COUNT'],
        email: ENV['EMAIL'],
        price_id: ENV['PRICE_ID']
    ).start!
  end
end
