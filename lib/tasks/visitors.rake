namespace :visitors do
  desc 'update'
  task update: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 40.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now

    (start_day.to_date..end_day.to_date).each do |day|
      search_logs = SearchLog.except_crawler.where(created_at: day.to_time.all_day).where.not(session_id: -1)
      session_ids = search_logs.uniq.pluck(:session_id)

      counts = search_logs.where(session_id: session_ids).where.not(user_id: -1).group(:session_id).count

      user_ids = search_logs
        .where(session_id: session_ids)
        .where.not(user_id: -1)
        .order(created_at: :asc)
        .pluck(:session_id, :user_id)
        .to_h
      users = User.where(id: user_ids.values).index_by(&:id)

      visitors = Visitor.where(session_id: session_ids).to_a
      visitors.select { |v| v.created_at > day }.each { |v| v.assign_attributes(created_at: day) }
      visitors.select { |v| v.updated_at < day }.each { |v| v.assign_attributes(updated_at: day) }

      visitors += (session_ids - visitors.map(&:session_id)).map { |s| Visitor.new(session_id: s, created_at: day, updated_at: day) }
      visitors, not_changed = visitors.partition { |v| v.changed? }

      visitors.each do |visitor|
        session_id = visitor.session_id
        if counts[session_id] && counts[session_id] > 0
          user = users[user_ids[session_id]]
          visitor.assign_attributes(user_id: user.id, uid: user.uid, screen_name: user.screen_name)
        end
      end

      puts "#{day} changed: #{visitors.size}, not changed: #{not_changed.size}, users: #{users.size}"

      Visitor.import visitors, on_duplicate_key_update: %i(user_id uid screen_name created_at updated_at), validate: false, timestamps: false
    end
  end
end
