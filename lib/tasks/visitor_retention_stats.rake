namespace :visitor_retention_stats do
  desc 'update'
  task update: :environment do
    start_day = Time.zone.parse(ENV['START'])
    end_day = Time.zone.parse(ENV['END'])
    stats = []
    diffs = [1, 2, 3, 4, 5, 6, 7, 14, 30]

    (start_day.to_date..end_day.to_date).each do |day|
      session_ids = Visitor.where(created_at: day.to_time.all_day).pluck(:session_id)

      stat = VisitorRetentionStat.find_or_initialize_by(date: day)
      stat.total = session_ids.size
      diffs.each do |diff|
        stat["#{diff}_days"] = SearchLog.except_crawler.where(session_id: session_ids, created_at: (day + diff.day).to_time.all_day).count('distinct session_id')
      end

      puts "#{day}: #{([stat.total] + diffs.map { |n| stat["#{n}_days"] }).join(', ')}"

      stats << stat if stat.changed?
    end

    if stats.any?
      VisitorRetentionStat.import(stats, on_duplicate_key_update: (%i(total) + diffs.map { |n| "#{n}_days" }), validate: false)
    end
  end
end
