namespace :orders do
  task update_stripe_attributes: :environment do
    Order.where(canceled_at: nil).find_each.with_index do |order, i|
      interval = (0.1 * i).floor
      SyncOrderEmailWorker.perform_in(interval, order.id)
      SyncOrderSubscriptionWorker.perform_in(interval, order.id)
    end
  end

  task print_statuses: :environment do
    Order.unexpired.find_each do |order|
      customer = Stripe::Customer.retrieve(order.customer_id)
      invoices = Stripe::Invoice.list(customer: customer.id, limit: 3).data
      charges = Stripe::Charge.list(customer: customer.id, limit: 3).data

      invoices_status = invoices.map(&:status)
      invoices_paid = invoices.map(&:paid)

      charges_status = charges.map(&:status)
      charges_paid = charges.map(&:paid)
      charges_refunded = charges.map(&:refunded)

      puts "id=#{order.id} customer=#{customer.id} invoices.status=#{invoices_status} invoices.paid=#{invoices_paid} charges.status=#{charges_status} charges.paid=#{charges_paid} charges.refunded=#{charges_refunded}"
    end
  end

  task print_invalid_order: :environment do
    Order.unexpired.find_each do |order|
      customer = Stripe::Customer.retrieve(order.customer_id)
      invoices = Stripe::Invoice.list(customer: customer.id, limit: 3).data
      charges = Stripe::Charge.list(customer: customer.id, limit: 3).data

      if (invoices[0] && invoices[0].status != 'draft' && !invoices[0].paid) || (charges[0] && charges[0].paid && charges[0].refunded)
        puts "found #{order.id}"
      else
        print '.'
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
    ).start
  end
end
