namespace :users do
  desc 'copy unauthorized uids'
  task copy_unauthorized_uids: :environment do
    uids = Util::UnauthorizedUidList.new(Redis.client).to_a
    uids.each_slice(1000).each do |uids_array|
      User.where(uid: uids_array).update_all(authorized: false)
    end
  end

  desc 'update timestamps'
  task update_timestamps: :environment do
    start_day = ENV['START'] ? Time.zone.parse(ENV['START']) : (Time.zone.now - 30.days)
    end_day = ENV['END'] ? Time.zone.parse(ENV['END']) : Time.zone.now

    (start_day.to_date..end_day.to_date).each do |day|
      search_logs = SearchLog.where(user_id: User.pluck(:id)).where(created_at: day.to_time.all_day).order(created_at: :asc)
      users = User.where(id: search_logs.pluck(:user_id)).index_by { |u| u.id }

      search_logs.each do |log|
        user = users[log.user_id]
        assign_timestamp(user, :first_access_at, log.created_at) { |_user, attr, value| _user[attr] > value }
        assign_timestamp(user, :last_access_at, log.created_at) { |_user, attr, value| _user[attr] < value }
      end

      search_logs.where(action: 'show').each do |log|
        user = users[log.user_id]
        assign_timestamp(user, :first_search_at, log.created_at) { |_user, attr, value| _user[attr] > value }
        assign_timestamp(user, :last_search_at, log.created_at) { |_user, attr, value| _user[attr] < value }
      end

      SignInLog.where(created_at: day.to_time.all_day, user_id: users.keys).each do |log|
        user = users[log.user_id]
        assign_timestamp(user, :first_sign_in_at, log.created_at) { |_user, attr, value| _user[attr] > value }
        assign_timestamp(user, :last_sign_in_at, log.created_at) { |_user, attr, value| _user[attr] < value }
      end

      changed, not_changed = users.values.partition { |u| u.changed? }
      puts "#{day} users: #{users.size}, changed: #{changed.size}, not changed: #{not_changed.size}"

      if changed.any?
        User.import changed, on_duplicate_key_update: %i(first_access_at last_access_at first_search_at last_search_at first_sign_in_at last_sign_in_at), validate: false, timestamps: false
      end
    end

  end

  def assign_timestamp(user, attr, value)
    if user[attr].nil? || yield(user, attr, value)
      user[attr] = value
    end
  end
end
