namespace :orders do
  task verify: :environment do |task|
    orders = Order.select(:id, :canceled_at, :subscription_id).where(canceled_at: nil)

    orders.find_each(batch_size: 10) do |order|
      subscription = Stripe::Subscription.retrieve(order.subscription_id)
      if subscription.canceled_at
        SendMessageToSlackWorker.perform_async(:orders_warning, "Order to be deleted order_id=#{order.id} subscription_id=#{order.subscription_id}")
      end
    end

    puts "#{Time.zone.now.to_s(:db)} task=#{task.name} total=#{orders.size}"
  end

  task update_email: :environment do |task|
    # This task is divided as there are not many records
    orders = Order.where(canceled_at: nil).where(email: nil).where('created_at > ?', (1.hour + 5.minutes).ago)

    orders.find_each(batch_size: 10) do |order|
      customer = Stripe::Customer.retrieve(order.customer_id)
      if (email = customer.email)
        order.update(email: email)
        SlackBotClient.channel(:orders_sync).post_message("Updated changes=#{order.saved_changes.except('updated_at')}")
      end
    end

    puts "#{Time.zone.now.to_s(:db)} task=#{task.name} total=#{orders.size}"
  end

  task update_trial_end: :environment do |task|
    # This task is divided as there are not many records
    orders = Order.where(canceled_at: nil).where(trial_end: nil).where('created_at > ?', 15.days.ago)

    orders.find_each(batch_size: 10) do |order|
      subscription = Stripe::Subscription.retrieve(order.subscription_id)
      if (trial_end = subscription.trial_end)
        order.update(trial_end: trial_end)
        SlackBotClient.channel(:orders_sync).post_message("Updated changes=#{order.saved_changes.except('updated_at')}")
      end
    end

    puts "#{Time.zone.now.to_s(:db)} task=#{task.name} total=#{orders.size}"
  end

  task send_charge_failed_message: :environment do
    from = ENV['FROM']
    to_addresses = ENV['TO'].split(',')

    to_addresses.each do |to|
      subject = I18n.t('workers.charge_failed_reminder.subject')
      body = I18n.t('workers.charge_failed_reminder.body')
      GmailClient.new(from).send_message(from, to, subject, body)
      puts body
      puts '----------------------------------------------------'
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
    ActivateSubscriptionTask.new(
        screen_name: ENV['SCREEN_NAME'],
        months_count: ENV['MONTHS_COUNT'],
        email: ENV['EMAIL'],
        price_id: ENV['PRICE_ID']
    ).start
  end
end
