class ImportReplyingRepliedAndFavoritesWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid)
    started_at = Time.zone.now
    chk1 = nil
    login_user = user_id == -1 ? nil : User.find(user_id)
    client = login_user.nil? ? Bot.api_client : login_user.api_client
    twitter_user = TwitterUser.latest(uid)
    @retry_count = 0
    @wait_seconds = 0.0

    uids = (twitter_user.replying_uids + twitter_user.replied_uids(login_user: login_user) + twitter_user.favoriting_uids).uniq
    begin
      t_users = client.users(uids)
    rescue Twitter::Error::Unauthorized => e
      if e.message == 'Invalid or expired token.'
        User.find_by(id: user_id)&.update(authorized: false)
      end

      message = "#{e.class} #{e.message} #{user_id} #{uid}"
      UNAUTHORIZED_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)
    rescue => e
      logger.warn "#{e.class} #{e.message} #{user_id} #{uid} size: #{uids.size}"
    end
    return if t_users.blank?

    users = t_users.map { |user| to_array(user) }
    users.sort_by!(&:first)

    chk1 = Time.zone.now
    _retry_with_transaction!('import replying, replied and favoriting', retry_limit: 3) { TwitterDB::User.import_each_slice(users) }

  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      User.find_by(id: user_id)&.update(authorized: false)
    end

    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    UNAUTHORIZED_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)
  rescue ActiveRecord::StatementInvalid => e
    logger.warn "Deadlock found when trying to get lock #{user_id} #{uid} (retry #{@retry_count}, wait #{@wait_seconds}) start: #{short_hour(started_at)} chk1: #{short_hour(chk1)} finish: #{short_hour(Time.zone.now)}"
    logger.info e.backtrace.join "\n"
  rescue Twitter::Error::NotFound => e
    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    NOT_FOUND_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user&.screen_name}"
  end

  private

  def to_array(user)
    [user.id, user.screen_name, user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1]
  end
end
