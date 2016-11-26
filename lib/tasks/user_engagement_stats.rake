namespace :user_engagement_stats do
  desc 'update'
  task update: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 40.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now
    stats = []
    diffs = (1..30).to_a
    columns = %i(total) + diffs.map { |n| "#{n}_days" } + diffs.map { |n| "before_#{n}_days" }

    (start_day.to_date..end_day.to_date).each do |day|
      user_ids = SearchLog.user_ids(created_at: day.to_time.all_day)

      stat = UserEngagementStat.find_or_initialize_by(date: day)
      stat.total = user_ids.size
      counts = user_ids.each_with_object(Hash.new(0)) { |id, memo| memo[id] += 1 }
      diffs.each do |diff|
        ids = SearchLog.user_ids(user_id: user_ids, created_at: (day - diff.day).to_time.all_day)
        ids.each { |id| counts[id] += 1 }
        stat["before_#{diff}_days"] = ids.size
      end

      diffs.each do |diff|
        stat["#{diff}_days"] = counts.select { |_, v| v == diff }.size
      end
      stats << stat if stat.changed?

      puts "#{day}: #{columns.map { |c| stat[c] }.join(', ')}"
    end

    if stats.any?
      UserEngagementStat.import(stats, on_duplicate_key_update: columns, validate: false)
    end
  end
end
