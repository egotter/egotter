namespace :shop_orders do
  task send_email: :environment do
    from = ENV['FROM']
    to = ENV['TO']
    subject = I18n.t('email_messages.shop_order_ask_id_subject')
    body = I18n.t('email_messages.shop_order_ask_id_body')
    GmailClient.new(from).send_message(from, to, subject, body)
    puts body
  end

  task send_remind_email: :environment do
    from = ENV['FROM']
    to = ENV['TO']
    subject = 'Re: ' + I18n.t('email_messages.shop_order_ask_id_subject')
    body = I18n.t('email_messages.shop_order_reminder_body')
    client = GmailClient.new(from)
    message = client.messages(to: to, subject: I18n.t('email_messages.shop_order_ask_id_subject'), limit: 1)[0]

    client.send_message(from, to, subject, body, thread_id: message.thread_id)
    puts body
  end
end
