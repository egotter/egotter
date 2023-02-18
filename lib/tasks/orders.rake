namespace :orders do
  task update_stripe_attributes: :environment do |task|
    processed_count = 0
    order_ids = []
    check_email_time = (1.hour + 5.minutes).ago
    start = Time.zone.now

    Order.select(:id).where(canceled_at: nil).find_in_batches do |orders|
      order_ids.concat(orders.map(&:id))
    end

    order_ids.each.with_index do |id, i|
      order = Order.select(:id, :created_at).find(id)
      SyncOrderEmailWorker.new.perform(order.id) if order.created_at > check_email_time
      SyncOrderSubscriptionWorker.new.perform(order.id)
      processed_count += 1

      if Time.zone.now - start > 50.minutes
        raise "#{task.name}: Timeout total=#{order_ids.size} processed=#{processed_count} elapsed=#{Time.zone.now - start}"
      end
    end

    Airbag.info "#{task.name}: Finished total=#{order_ids.size} processed=#{processed_count} elapsed=#{Time.zone.now - start}"
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
    ActivateSubscriptionTask.new(
        screen_name: ENV['SCREEN_NAME'],
        months_count: ENV['MONTHS_COUNT'],
        email: ENV['EMAIL'],
        price_id: ENV['PRICE_ID']
    ).start
  end
end
