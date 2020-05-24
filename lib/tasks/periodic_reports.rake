namespace :periodic_reports do
  desc 'Send messages'
  task send_messages: :environment do
    ids1 = StartSendingPeriodicReportsTask.dm_received_user_ids
    ids3 = StartSendingPeriodicReportsTask.new_user_ids(2.days.ago, Time.zone.now)
    user_ids = (ids1 + ids3).uniq

    StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start!

    puts "ids1=#{ids1.size} ids3=#{ids3.size} user_ids=#{user_ids.size}"
  end

  desc 'Send messages only if changed'
  task send_messages_only_if_changed: :environment do
    ids1 = StartSendingPeriodicReportsTask.dm_received_user_ids
    ids3 = StartSendingPeriodicReportsTask.new_user_ids(2.days.ago, Time.zone.now)
    user_ids = (ids1 + ids3).uniq

    StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second, send_only_if_changed: true).start!

    puts "ids1=#{ids1.size} ids3=#{ids3.size} user_ids=#{user_ids.size}"
  end

  desc 'Send remind messages'
  task send_remind_messages: :environment do
    user_ids = StartSendingPeriodicReportsTask.allotted_messages_will_expire_user_ids

    StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start_reminding!

    puts "user_ids=#{user_ids.size}"
  end
end
