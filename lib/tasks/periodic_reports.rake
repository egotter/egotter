namespace :periodic_reports do
  task send_messages: :environment do
    StartPeriodicReportsTask.new(period: ENV['PERIOD']).start!
  end

  task send_remind_messages: :environment do
    task = StartPeriodicReportsRemindersTask.new
    task.start!
    puts "user_ids=#{task.user_ids.size}"
  end

  # TODO Remove later
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

  task create_records: :environment do
    StartPeriodicReportsCreatingRecordsTask.new(period: ENV['PERIOD']).start!
  end

  namespace :send_messages do
    task morning: :environment do
      StartPeriodicReportsTask.new(period: 'morning').start!
    end

    task afternoon: :environment do
      StartPeriodicReportsTask.new(period: 'afternoon').start!
    end

    task night: :environment do
      StartPeriodicReportsTask.new(period: 'night').start!
    end
  end

  task delete: :environment do
    limit = ENV['LIMIT']&.to_i || 100
    batch_size = [limit, 1000].min
    min_date = Time.zone.parse(ENV['START_DATE'])
    max_date = Time.zone.parse(ENV['END_DATE'])
    processed_count = 0
    stopped = false

    100.times do |n|
      start_date = [min_date + n.days, max_date].min
      end_date = [min_date + (n + 1).days, max_date].min
      target_ids = []

      PeriodicReport.from('periodic_reports USE INDEX(index_periodic_reports_on_created_at)').
          where(created_at: start_date..end_date).select(:id).find_in_batches(batch_size: batch_size) do |records|
        next if records.empty?
        target_ids << records.map(&:id)
      end

      target_ids.each do |ids|
        PeriodicReport.where(id: ids).delete_all
        print '.'

        if (processed_count += ids.size) >= limit
          stopped = true
          break
        end
      end

      break if stopped || start_date >= max_date
    end

    puts "\nprocessed #{processed_count}"
  end
end
