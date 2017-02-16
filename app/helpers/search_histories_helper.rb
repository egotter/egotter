module SearchHistoriesHelper

  TTL = Rails.env.development? ? 1.second : 5.minutes

  def search_histories_list
    redis.fetch("search_histories:#{current_user_id}", ttl: TTL) do
      uids = BackgroundSearchLog.success_logs(current_user_id).pluck(:uid).unix_uniq.take(10)
      twitter_users = TwitterUser.where(uid: uids.uniq).index_by { |tu| tu.uid.to_i }
      uids.map { |uid| twitter_users[uid.to_i] }.compact
    end
  end
end
