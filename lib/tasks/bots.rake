namespace :bots do
  desc 'Invalidate expired credentials'
  task invalidate_expired_credentials: :environment do
    puts InvalidateExpiredCredentialsWorker.perform_async
  end
end
