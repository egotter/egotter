namespace :bots do
  desc 'update authorized'
  task update_authorized: :environment do
    Bot.verify_credentials.each do |cred|
      bot = Bot.find(cred[:id])
      bot.authorized = cred[:authorized]
      if bot.changed?
        bot.save!

        message = "Bot#authorized is changed #{bot.saved_changes}"
        SlackClient.bot.send_message(message)
        puts message
      end
    end
  end
end
