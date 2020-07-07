namespace :bots do
  desc 'Invalidate expired credentials'
  task invalidate_expired_credentials: :environment do
    Timeout.timeout(60.seconds) do
      Bot.invalidate_expired_credentials
    end
  end
end
