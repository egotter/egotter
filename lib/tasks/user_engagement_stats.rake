namespace :user_engagement_stats do
  desc 'update'
  task update: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 40.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now
    stats = []
    diffs = (1..30).to_a

    (start_day.to_date..end_day.to_date).each do |day|
      user_ids = SearchLog.user_ids(created_at: day.to_time.all_day)

      stat = UserEngagementStat.find_or_initialize_by(date: day)
      stat.total = user_ids.size
      counts = Hash.new(0)
      diffs.each do |diff|
        SearchLog
          .user_ids(user_id: user_ids, created_at: (day - diff.day).to_time.all_day)
          .each { |id| counts[id] += 1 }
      end

      diffs.each do |diff|
        stat["#{diff}_days"] = counts.select { |_, v| v == diff }.size
      end
      stats << stat if stat.changed?

      puts "#{day}: #{([stat.total] + diffs.map { |n| stat["#{n}_days"] }).join(', ')}"
    end

    if stats.any?
      UserEngagementStat.import(stats, on_duplicate_key_update: (%i(total) + diffs.map { |n| "#{n}_days" }), validate: false)
    end
  end
end
