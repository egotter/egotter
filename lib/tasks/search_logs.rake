namespace :search_logs do
  desc 'update first_time'
  task update_first_time: :environment do
    changed = []
    processed = 0
    imported = 0
    Visitor.order(first_access_at: :asc).pluck(:session_id).each_slice(10000) do |session_ids|
      search_logs = SearchLog
        .except_crawler
        .where(session_id: session_ids)
        .order(created_at: :asc)
        .each_with_object(Hash.new { |h, k| h[k] = [] }) { |log, memo| memo[log.session_id] << log }

      search_logs.each do |_, logs|
        logs.shift.tap { |log| changed << [log.id, true, log.created_at] unless log.first_time? }
        logs.select { |log| log.first_time? }.each { |log| changed << [log.id, false, log.created_at] }
      end

      if changed.any?
        imported += changed.size
        SearchLog.import(%i(id first_time created_at), changed, validate: false, timestamps: false, on_duplicate_key_update: %i(first_time))
        changed = []
      end

      processed += session_ids.size
      puts "#{Time.zone.now}: #{processed}, #{imported}"
    end
  end
end
