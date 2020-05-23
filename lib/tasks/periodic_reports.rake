namespace :periodic_reports do
  desc 'Send messages'
  task send_messages: :environment do
    ids1 = StartSendingPeriodicReportsTask.dm_received_user_ids
    ids3 = StartSendingPeriodicReportsTask.new_user_ids(2.days.ago, Time.zone.now)
    user_ids = (ids1 + ids3).uniq

    puts "ids1=#{ids1.size} ids3=#{ids3.size} user_ids=#{user_ids.size}"

    StartSendingPeriodicReportsTask.new(user_ids: user_ids, delay: 1.second).start!
  end

  desc 'Send remind-reply messages'
  task send_remind_reply_messages: :environment do
    sigint = Util::Sigint.new.trap

    send_limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 100
    send_count = 0

    uids = GlobalDirectMessageReceivedFlag.new.to_a
    uids.each do |uid|
      user = User.find_by(uid: uid)
      next unless user
      next if StopPeriodicReportRequest.exists?(user_id: user.id)

      ttl = GlobalDirectMessageReceivedFlag.new.remaining(user.uid)
      if ttl && 30.seconds < ttl && ttl < PeriodicReport::REMAINING_TTL_HARD_LIMIT
        PeriodicReport.new(user: user).send_remind_reply_message
        send_count += 1
      end

      break if send_count >= send_limit
    end

    puts "send_count=#{send_count} send_limit=#{send_limit}"
  end
end
