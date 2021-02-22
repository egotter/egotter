namespace :periodic_reports do
  desc 'Send messages'
  task send_messages: :environment do
    user_ids = StartPeriodicReportsTask.morning_user_ids
    StartPeriodicReportsTask.new(user_ids: user_ids).start!
    puts "user_ids=#{user_ids.size}"
  end

  desc 'Send messages only if changed'
  task send_messages_only_if_changed: :environment do
    user_ids = StartPeriodicReportsTask.morning_user_ids
    StartPeriodicReportsTask.new(user_ids: user_ids, send_only_if_changed: true).start!
    puts "user_ids=#{user_ids.size}"
  end

  desc 'Send remind messages'
  task send_remind_messages: :environment do
    task = StartPeriodicReportsRemindersTask.new
    task.start!
    puts "user_ids=#{task.user_ids.size}"
  end

  desc 'Send re-engage messages'
  task send_reengage_messages: :environment do
    start_date = ENV['START_DATE'] ? Time.zone.parse(ENV['START_DATE']) : 7.days.ago
    end_date = ENV['END_DATE'] ? Time.zone.parse(ENV['END_DATE']) : Time.zone.now
    date_range = start_date.beginning_of_day..end_date.end_of_day
    puts "start_date=#{date_range.first} end_date=#{date_range.last}"

    limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 10000
    puts "limit=#{limit}"

    users = User.where(created_at: date_range).select(:id, :uid, :authorized).to_a
    puts "users=#{users.size} (all)"

    users.select!(&:authorized)
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
    puts "users=#{users.size} (limited)"

    if users.any?
      StartPeriodicReportsTask.new(user_ids: users.map(&:id)).start!
    end
  end

  namespace :send_messages do
    desc 'Send morning messages'
    task morning: :environment do |task|
      user_ids = StartPeriodicReportsTask.morning_user_ids
      StartPeriodicReportsTask.new(user_ids: user_ids).start!
      puts "user_ids=#{user_ids.size} task_name=#{task.name}"
    end

    desc 'Send afternoon messages'
    task afternoon: :environment do |task|
      user_ids = StartPeriodicReportsTask.afternoon_user_ids
      StartPeriodicReportsTask.new(user_ids: user_ids).start!
      puts "user_ids=#{user_ids.size} task_name=#{task.name}"
    end

    desc 'Send night messages'
    task night: :environment do |task|
      user_ids = StartPeriodicReportsTask.night_user_ids
      StartPeriodicReportsTask.new(user_ids: user_ids).start!
      puts "user_ids=#{user_ids.size} task_name=#{task.name}"
    end
  end
end
