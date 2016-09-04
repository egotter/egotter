namespace :onesignal do
  desc 'send'
  task send: :environment do
    Onesignal.send(ENV['USER_IDS'].split(','))
  end
end
