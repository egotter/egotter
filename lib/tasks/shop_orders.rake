namespace :shop_orders do
  task send_email: :environment do
    from = ENV['FROM']
    to_addresses = ENV['TO'].split(',')

    to_addresses.each do |to|
      if (users = User.select(:id, :screen_name).where(email: to)).any?
        puts 'Users found'
        users.each { |user| puts "email=#{to} id=#{user.id} screen_name=#{user.screen_name}" }
      end

      if (orders = Order.select(:id, :user_id).where(email: to)).any?
        puts 'Orders found'
        orders.each { |order| puts "email=#{to} id=#{order.id} user_id=#{order.user_id} screen_name=#{order.user.screen_name}" }
      end

      subject = I18n.t('email_messages.shop_order_ask_id_subject')
      body = I18n.t('email_messages.shop_order_ask_id_body')
      GmailClient.new(from).send_message(from, to, subject, body)
      puts body

      puts '----------------------------------------------------'
    end
  end

  task send_remind_email: :environment do
    from = ENV['FROM']
    to_addresses = ENV['TO'].split(',')

    to_addresses.each do |to|
      if (users = User.select(:id, :screen_name).where(email: to)).any?
        puts 'Users found'
        users.each { |user| puts "email=#{to} id=#{user.id} screen_name=#{user.screen_name}" }
      end

      if (orders = Order.select(:id, :user_id).where(email: to)).any?
        puts 'Orders found'
        orders.each { |order| puts "email=#{to} id=#{order.id} user_id=#{order.user_id} screen_name=#{order.user.screen_name}" }
      end

      subject = 'Re: ' + I18n.t('email_messages.shop_order_ask_id_subject')
      body = I18n.t('email_messages.shop_order_reminder_body')
      client = GmailClient.new(from)
      message = client.messages(to: to, subject: I18n.t('email_messages.shop_order_ask_id_subject'), limit: 1)[0]

      client.send_message(from, to, subject, body, thread_id: message.thread_id)
      puts body

      puts '----------------------------------------------------'
    end
  end
end
