class ImportReplyingRepliedAndFavoritesWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    login_user = user_id == -1 ? nil : User.find(user_id)
    client = login_user.nil? ? Bot.api_client : login_user.api_client
    twitter_user = TwitterUser.latest(uid)

    uids = (twitter_user.replying_uids + twitter_user.replied_uids(login_user: login_user) + twitter_user.favoriting_uids).uniq
    t_users = (client.users(uids) rescue [])
    users = t_users.map { |user| [user.id, user.screen_name, user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1] }
    users.sort_by!(&:first)

    create_columns = %i(uid screen_name user_info friends_size followers_size)
    update_columns = %i(uid screen_name user_info)
    retrying = false
    begin
      Rails.logger.silence { ActiveRecord::Base.transaction {
        users.each_slice(1000) do |array|
          TwitterDB::User.import(create_columns, array, on_duplicate_key_update: update_columns, validate: false)
        end
      }}
    rescue ActiveRecord::StatementInvalid => e
      if !retrying && e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        retrying = true
        retry
      end
      raise
    end

  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user.screen_name}"
  end
end
