namespace :shop_orders do
  task send_email: :environment do
    from = ENV['FROM']
    to = ENV['TO']
    subject = I18n.t('email_messages.shop_order_ask_id_subject')
    body = I18n.t('email_messages.shop_order_ask_id_body')
    GmailClient.new(from).send_message(from, to, subject, body)
    puts body
  end
end
