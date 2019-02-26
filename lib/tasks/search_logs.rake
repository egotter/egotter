namespace :search_logs do
  desc 'Archive'
  task archive: :environment do
    year = ENV['YEAR']
    month = ENV['MONTH']
    raise 'Specify YEAR and MONTH' if year.blank? || month.blank?

    table_name = "search_logs_#{year}#{month}"
    ActiveRecord::Base.connection.execute("CREATE TABLE IF NOT EXISTS #{table_name} LIKE search_logs")

    start_time = Time.zone.parse("#{year}-#{month}-01 00:00:00").beginning_of_month.to_s(:db)
    end_time = Time.zone.parse("#{year}-#{month}-01 00:00:00").end_of_month.to_s(:db)
    puts "Archive #{SearchLog.where(created_at: start_time..end_time).size} records"
    ActiveRecord::Base.connection.execute("INSERT INTO #{table_name} select * from search_logs where created_at BETWEEN '#{start_time}' AND '#{end_time}' and device_type not in ('crawler', 'UNKNOWN', 'misc')")
    ActiveRecord::Base.connection.execute("DELETE from search_logs where created_at BETWEEN '#{start_time}' AND '#{end_time}' and device_type not in ('crawler', 'UNKNOWN', 'misc')")
  end

  desc 'update first_time'
  task update_first_time: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 40.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now

    (start_day.to_date..end_day.to_date).each do |day|
      session_ids = SearchLog.session_ids(created_at: day.to_time.all_day)
      search_logs = SearchLog # TODO time‐consuming
        .where(session_id: session_ids)
        .order(created_at: :asc)
        .each_with_object(Hash.new { |h, k| h[k] = [] }) { |log, memo| memo[log.session_id] << log }

      # logs.shift.tap { |log| changed << [log.id, true, log.created_at] unless log.first_time? }
      # logs.select { |log| log.first_time? }.each { |log| changed << [log.id, false, log.created_at] }
      # changed, not_changed = search_logs.values.flatten.partition { |l| l.changed? }

      # `Model#changed?` is too much time‐consuming, so changed and not_changed are created manually.
      changed, not_changed = [], []
      search_logs.each do |_, logs|
        first = logs.shift
        if first.first_time?
          not_changed << first
        else
          first.first_time = true
          changed << first
        end

        logs.each do |log|
          if log.first_time?
            log.first_time = false
            changed << log
          else
            not_changed << log
          end
        end
      end
      puts "#{day} search_logs: #{search_logs.size}, changed: #{changed.size}, not changed: #{not_changed.size}"

      if changed.any?
        changed = changed.map { |log| [log.id, log.first_time, log.created_at] }
        SearchLog.import(%i(id first_time created_at), changed, validate: false, timestamps: false, on_duplicate_key_update: %i(first_time))
      end
    end
  end
end
