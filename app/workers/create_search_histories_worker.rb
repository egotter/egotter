class CreateSearchHistoriesWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id)
    uids = BackgroundSearchLog.success_logs(user_id).pluck(:uid).unix_uniq.take(10)
    twitter_users = TwitterUser.where(uid: uids.uniq).index_by { |tu| tu.uid.to_i }
    json =
      uids.map { |uid| twitter_users[uid.to_i] }.compact.map do |twitter_user|
        {
          uid: twitter_user.uid,
          screen_name: twitter_user.screen_name,
          description: twitter_user.description,
          profile_image_url_https: twitter_user.profile_image_url_https.to_s
        }
      end.to_json
    Util::SearchHistories.new(Redis.client).set(user_id, json)
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{user_id}"
  end
end
