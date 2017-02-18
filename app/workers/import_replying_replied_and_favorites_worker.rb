class ImportReplyingRepliedAndFavoritesWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, twitter_user_id)
    login_user = user_id == -1 ? nil : User.find(user_id)
    client = login_user.nil? ? Bot.api_client : login_user.api_client
    twitter_user = TwitterUser.find(twitter_user_id)

    uids = (twitter_user.replying_uids + twitter_user.replied_uids(login_user: login_user) + twitter_user.favoriting_uids).uniq
    t_users = (client.users(uids) rescue [])
    users = t_users.map { |user| [user.id, user.screen_name, user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1] }

    Rails.logger.silence { ActiveRecord::Base.transaction {
      users.each_slice(1000) do |array|
        TwitterDB::User.import(%i(uid screen_name user_info friends_size followers_size), array, on_duplicate_key_update: %i(uid screen_name user_info), validate: false)
      end
    }}

    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{twitter_user.uid} #{twitter_user.screen_name}"

  rescue => e
    message = e.message.truncate(200)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{twitter_user_id}"
    logger.info e.backtrace.join "\n"
  end
end
