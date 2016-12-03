namespace :visitors do
  desc 'copy from first_access_at to created_at'
  task copy_from_first_access_at_to_created_at: :environment do
    Visitor.find_in_batches(batch_size: 10000) do |visitors|
      visitors.each { |v| v.assign_attributes(created_at: v.first_access_at, updated_at: v.last_access_at) }
      Visitor.import visitors, on_duplicate_key_update: %i(created_at updated_at), validate: false, timestamps: false
    end
  end

  desc 'update'
  task update: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : 3.days.ago
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now

    (start_day.to_date..end_day.to_date).each do |day|
      search_logs = SearchLog.except_crawler.where(created_at: day.to_time.all_day).order(created_at: :asc)

      visitors = find_or_initialize_by(search_logs.uniq.pluck(:session_id)).index_by(&:session_id)
      search_logs.each do |log|
        visitor = visitors[log.session_id]
        assign_timestamp(visitor, :first_access_at, log.created_at) { |_visitor, attr, value| _visitor[attr] > value }
        assign_timestamp(visitor, :last_access_at, log.created_at) { |_visitor, attr, value| _visitor[attr] < value }
        visitor.assign_attributes(first_channel: log.channel) if visitor.first_channel.blank?
      end

      users = User.where(id: search_logs.with_login.uniq.pluck(:user_id)).index_by(&:id)
      search_logs.with_login.each do |log|
        visitor = visitors[log.session_id]
        user = users[log.user_id]
        visitor.assign_attributes(user_id: user.id, uid: user.uid, screen_name: user.screen_name)
      end

      changed, not_changed = visitors.values.partition { |v| v.changed? }
      puts "#{day} visitors: #{visitors.size}, changed: #{changed.size}, not changed: #{not_changed.size}, users: #{users.size}"

      if changed.any?
        Visitor.import changed, on_duplicate_key_update: %i(user_id uid screen_name first_access_at last_access_at), validate: false
      end
    end
  end

  def find_or_initialize_by(session_ids)
    visitors = Visitor.where(session_id: session_ids).to_a
    visitors + (session_ids - visitors.map(&:session_id)).map { |s| Visitor.new(session_id: s) }
  end

  def assign_timestamp(visitor, attr, value)
    if visitor[attr].nil? || yield(visitor, attr, value)
      visitor[attr] = value
    end
  end
end
