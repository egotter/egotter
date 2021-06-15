namespace :violation_events do
  task create: :environment do
    user = User.find_by!(screen_name: ENV['SCREEN_NAME'])
    reason = ENV['REASON']
    CreateViolationEventWorker.perform_async(user.id, reason)
  end
end
