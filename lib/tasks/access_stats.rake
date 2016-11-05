namespace :access_stats do
  desc 'update'
  task update: :environment do
    start_day = Time.zone.parse(ENV['START'])
    end_day = Time.zone.parse(ENV['END'])
    stats = []

    (start_day.to_date..end_day.to_date).each do |day|
      user_ids = User.where(created_at: day.to_time.all_day).pluck(:id)

      stat = AccessStat.find_or_initialize_by(date: day)
      stat['0_days'] = user_ids.size
      [1, 3, 7, 14, 30].each do |diff|
        stat["#{diff}_days"] = SearchLog.except_crawler.where(user_id: user_ids, created_at: (day + diff.day).to_time.all_day).count('distinct user_id')
      end

      puts "#{day}: #{[0, 1, 3, 7, 14, 30].map { |n| stat["#{n}_days"] }.join(', ')}"

      stats << stat
    end

    if stats.any?
      AccessStat.import(stats, validate: false)
    end
  end
end
