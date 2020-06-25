namespace :bots do
  desc 'Invalidate expired credentials'
  task invalidate_expired_credentials: :environment do
    Bot.invalidate_expired_credentials
  end
end
