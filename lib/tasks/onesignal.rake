namespace :onesignal do
  desc 'send'
  task send: :environment do
    # TODO fix it.
    Onesignal.send(ENV['USER_IDS'].split(','))
  end
end
