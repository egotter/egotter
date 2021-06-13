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
        order.update(trial_end: order.fetch_stripe_subscription.trial_end)
      end
    end
  end

  task print_statuses: :environment do
    Order.unexpired.find_each do |order|
      customer = order.fetch_stripe_customer

      invoices_status = customer.invoices.map(&:status)
      invoices_paid = customer.invoices.map(&:paid)

      charges_status = customer.charges.map(&:status)
      charges_paid = customer.charges.map(&:paid)
      charges_refunded = customer.charges.map(&:refunded)

      puts "id=#{order.id} customer=#{customer.id} invoices.status=#{invoices_status} invoices.paid=#{invoices_paid} charges.status=#{charges_status} charges.paid=#{charges_paid} charges.refunded=#{charges_refunded}"
    end
  end

  desc 'Invalidate insufficient subscriptions'
  task invalidate_insufficient_subscriptions: :environment do
    Order.unexpired.find_each do |order|
      # TODO Confirm "c = customer.charges[0]; c.paid && !c.refunded"
      unless order.fetch_stripe_customer.invoices[0].paid
        order.cancel!('batch')
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
