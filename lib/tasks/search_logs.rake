namespace :search_logs do
  desc 'update first_time'
  task update_first_time: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 40.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now

    (start_day.to_date..end_day.to_date).each do |day|
      session_ids = SearchLog.session_ids(created_at: day.to_time.all_day)
      search_logs = SearchLog # TODO time‐consuming
        .where(session_id: session_ids)
        .order(created_at: :asc)
        .group_by { |log| log.session_id }

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

  desc 'users flow'
  task users_flow: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 40.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now

    (start_day.to_date..end_day.to_date).each do |day|
      session_ids = Visitor.where(last_access_at: day.to_time.all_day).pluck(:session_id)
      search_logs = SearchLog
        .where(session_id: session_ids, created_at: day.to_time.all_day)
        .order(created_at: :asc)
        .group_by { |log| log.session_id }

      flows =
        search_logs.each do |_, logs|
          logs.map do |log|
            query = %i(first_time landing medium channel).map { |column| [column, log[column]] }.to_h.to_query
            [log.action, query].join('?')
          end.join(';')
        end.each_with_object(Hash.new(0)) { |flow, memo| memo[flow] += 1 }.sort_by { |k, v| -v }

      flows.each { |flow, count| puts "#{'%4d' % count} #{flow}" }
    end
  end
end
