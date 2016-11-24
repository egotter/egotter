namespace :users do
  desc 'copy unauthorized uids'
  task copy_unauthorized_uids: :environment do
    uids = Util::UnauthorizedUidList.new(Redis.client).to_a
    uids.each_slice(1000).each do |uids_array|
      User.where(uid: uids_array).update_all(authorized: false)
    end
  end

  desc 'update first_access_at and last_access_at'
  task update_first_access_at_and_last_access_at: :environment do
    search_logs = SearchLog.where(user_id: User.pluck(:id)).order(created_at: :asc)
    users = User.where(id: search_logs.pluck(:user_id)).index_by { |u| u.id }

    search_logs.each do |log|
      user = users[log.user_id]
      user.assign_attributes(last_access_at: log.created_at)
      user.assign_attributes(first_access_at: log.created_at) if user.first_access_at.nil?
    end

    User.import users.values.select(&:changed?), on_duplicate_key_update: %i(first_access_at last_access_at), validate: false, timestamps: false
  end

  desc 'update first_search_at and last_search_at'
  task update_first_search_at_and_last_search_at: :environment do
    search_logs = SearchLog.where(user_id: User.pluck(:id), action: 'show').order(created_at: :asc)
    users = User.where(id: search_logs.pluck(:user_id)).index_by { |u| u.id }

    search_logs.each do |log|
      user = users[log.user_id]
      user.assign_attributes(last_search_at: log.created_at)
      user.assign_attributes(first_search_at: log.created_at) if user.first_search_at.nil?
    end

    User.import users.values.select(&:changed?), on_duplicate_key_update: %i(first_search_at last_search_at), validate: false, timestamps: false
  end
end
