class ImportReplyingRepliedAndFavoritesWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    login_user = user_id == -1 ? nil : User.find(user_id)
    client = login_user.nil? ? Bot.api_client : login_user.api_client
    twitter_user = TwitterUser.latest(uid)

    uids = (twitter_user.replying_uids + twitter_user.replied_uids(login_user: login_user) + twitter_user.favoriting_uids).uniq
    begin
      t_users = client.users(uids)
    rescue => e
      logger.warn "#{e.class} #{e.message} #{uids.size}"
    end
    return if t_users.nil? || t_users.empty?

    users = t_users.map { |user| [user.id, user.screen_name, user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1] }
    users.sort_by!(&:first)

    _retry_with_transaction!('import replying, replied and favoriting') { TwitterDB::User.import_each_slice(users) }

  rescue Twitter::Error::Unauthorized => e
    User.find_by(id: user_id)&.update(authorized: false) if e.message == 'Invalid or expired token.'
    logger.info "#{e.class} #{e.message} #{user_id} #{uid}"
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user.screen_name}"
  end
end
