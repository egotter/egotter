namespace :periodic_reports do
  desc 'Send messages'
  task send_messages: :environment do
    user_ids = StartSendingPeriodicReportsTask.morning_user_ids
    StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start!
    puts "user_ids=#{user_ids.size}"
  end

  desc 'Send messages only if changed'
  task send_messages_only_if_changed: :environment do
    user_ids = StartSendingPeriodicReportsTask.morning_user_ids
    StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second, send_only_if_changed: true).start!
    puts "user_ids=#{user_ids.size}"
  end

  desc 'Send remind messages'
  task send_remind_messages: :environment do
    user_ids = StartSendingPeriodicReportsTask.allotted_messages_will_expire_user_ids
    StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start_reminding!
    puts "user_ids=#{user_ids.size}"
  end

  desc 'Send re-engage messages'
  task send_reengage_messages: :environment do
    start_date = ENV['START_DATE'] ? Time.zone.parse(ENV['START_DATE']) : 7.days.ago
    end_date = ENV['END_DATE'] ? Time.zone.parse(ENV['END_DATE']) : Time.zone.now
    date_range = start_date.beginning_of_day..end_date.end_of_day
    puts "start_date=#{date_range.first} end_date=#{date_range.last}"

    limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 10000
    puts "limit=#{limit}"

    users = User.where(created_at: date_range, authorized: true).select(:id, :uid).to_a
    puts "users=#{users.size} (authorized)"

    users.select! do |user|
      !CreatePeriodicReportRequest.exists?(user_id: user.id)
    end
    puts "users=#{users.size} (not requested)"

    users.select! do |user|
      !StopPeriodicReportRequest.exists?(user_id: user.id)
    end
    puts "users=#{users.size} (not stop requested)"

    users.select! do |user|
      !PeriodicReport.messages_allotted?(user)
    end
    puts "users=#{users.size} (DM not received)"

    users = users.take(limit)
    puts "users=#{users.size} (limit)"

    StartSendingPeriodicReportsTask.new(user_ids: users.map(&:id), delay: 1.second).start!
  end

  namespace :send_messages do
    desc 'Send morning messages'
    task morning: :environment do
      user_ids = StartSendingPeriodicReportsTask.morning_user_ids
      StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start!
      puts "user_ids=#{user_ids.size}"
    end

    desc 'Send afternoon messages'
    task afternoon: :environment do
      user_ids = StartSendingPeriodicReportsTask.afternoon_user_ids
      StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start!
      puts "user_ids=#{user_ids.size}"
    end

    desc 'Send night messages'
    task night: :environment do
      user_ids = StartSendingPeriodicReportsTask.night_user_ids
      StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start!
      puts "user_ids=#{user_ids.size}"
    end
  end
end
