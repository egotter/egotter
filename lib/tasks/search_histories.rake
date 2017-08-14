namespace :search_histories do
  desc 'create'
  task create: :environment do

    user_ids =
      if ENV['USER_IDS']
        ENV['USER_IDS'].remove(' ').split(',').map(&:to_i)
      else
        User.active(30).pluck(:id)
      end

    user_ids.each do |user_id|
      next if SearchHistory.exists?(user_id: user_id)

      uids = BackgroundSearchLog.success_logs(user_id).pluck(:uid).unix_uniq.take(10).map(&:to_i)
      twitter_users = TwitterUser.where(uid: uids.uniq).index_by { |tu| tu.uid.to_i }

      uids.map { |uid| twitter_users[uid] }.compact.each do |twitter_user|
        SearchHistory.create!(user_id: user_id, uid: twitter_user.uid)
      end
    end

  end
end
