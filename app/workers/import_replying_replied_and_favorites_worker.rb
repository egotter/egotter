class ImportReplyingRepliedAndFavoritesWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid, options = {})
    started_at = Time.zone.now
    chk1 = nil
    login_user = user_id == -1 ? nil : User.find(user_id)
    client = login_user.nil? ? Bot.api_client : login_user.api_client
    twitter_user = TwitterUser.latest(uid)
    users = nil
    async = options.fetch('async', true)
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
      raise Error, e unless async
    end
    return if t_users.blank?

    users = t_users.map { |user| TwitterDB::User.to_import_format(user) }
    users.sort_by!(&:first)

    chk1 = Time.zone.now
    _retry_with_transaction!('import replying, replied and favoriting', retry_limit: 5, retry_timeout: 20.seconds) { TwitterDB::User.import_each_slice(users) }

  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      User.find_by(id: user_id)&.update(authorized: false)
    end

    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    UNAUTHORIZED_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)

    raise Error, e unless async
  rescue ActiveRecord::StatementInvalid => e
    logger.warn "Deadlock found #{user_id} #{uid} (size #{users&.size}, retry #{@retry_count}, wait #{@wait_seconds}) start: #{short_hour(started_at)} chk1: #{short_hour(chk1)} finish: #{short_hour(Time.zone.now)}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"

    raise Error, e unless async
  rescue Twitter::Error::NotFound => e
    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    NOT_FOUND_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)

    raise Error, e unless async
  rescue Twitter::Error => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    retry if e.message == 'Connection reset by peer - SSL_connect'

    raise Error, e unless async
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"

    raise Error, e unless async
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user&.screen_name}"
  end

  private

  class Error < StandardError
    def initialize(ex)
      super("#{ex.class} #{ex.message.truncate(100)}")
    end
  end
end
