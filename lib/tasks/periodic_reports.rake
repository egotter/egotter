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
