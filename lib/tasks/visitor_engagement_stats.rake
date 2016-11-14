namespace :visitor_engagement_stats do
  desc 'update'
  task update: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 40.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now
    stats = []
    diffs = (1..30).to_a

    (start_day.to_date..end_day.to_date).each do |day|
      session_ids = SearchLog
        .except_crawler
        .where(created_at: day.to_time.all_day)
        .where.not(session_id: -1)
        .uniq
        .pluck(:session_id)

      stat = VisitorEngagementStat.find_or_initialize_by(date: day)
      stat.total = session_ids.size
      counts = Hash.new(0)
      diffs.each do |diff|
        ids = SearchLog
          .except_crawler
          .where(session_id: session_ids, created_at: (day - diff.day).to_time.all_day)
          .uniq
          .pluck(:session_id)

        ids.each { |id| counts[id] += 1 }
      end

      diffs.each do |diff|
        stat["#{diff}_days"] = counts.select { |_, v| v == diff }.size
      end
      stats << stat if stat.changed?

      puts "#{day}: #{([stat.total] + diffs.map { |n| stat["#{n}_days"] }).join(', ')}"
    end

    if stats.any?
      VisitorEngagementStat.import(stats, on_duplicate_key_update: (%i(total) + diffs.map { |n| "#{n}_days" }), validate: false)
    end
  end
end
