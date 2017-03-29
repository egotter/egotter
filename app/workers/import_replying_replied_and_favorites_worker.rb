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
      handle_unauthorized_exception(e, user_id: user_id, uid: uid, twitter_user_id: twitter_user.id)
      raise WorkerError.new(self.class, jid) unless async
    rescue => e
      logger.warn "#{e.class} #{e.message} #{user_id} #{uid} size: #{uids.size}"
      raise WorkerError.new(self.class, jid) unless async
    end
    return if t_users.blank?

    users = t_users.map { |user| TwitterDB::User.to_import_format(user) }
    users.sort_by!(&:first)

    chk1 = Time.zone.now
    _retry_with_transaction!('import replying, replied and favoriting', retry_limit: 5, retry_timeout: 20.seconds) { TwitterDB::User.import_each_slice(users) }

  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id, uid: uid, twitter_user_id: twitter_user&.id)
    raise WorkerError.new(self.class, jid) unless async
  rescue ActiveRecord::StatementInvalid => e
    if async
      logger.warn "Deadlock found #{user_id} #{uid} (size #{users&.size}, retry #{@retry_count}, wait #{@wait_seconds}) start: #{short_hour(started_at)} chk1: #{short_hour(chk1)} finish: #{short_hour(Time.zone.now)}"
      logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
    else
      raise WorkerError.new(self.class, jid)
    end
  rescue Twitter::Error::NotFound => e
    handle_not_found_exception(e, user_id: user_id, uid: uid)
    raise WorkerError.new(self.class, jid) unless async
  rescue Twitter::Error => e
    retry if e.message == 'Connection reset by peer - SSL_connect'

    if async
      logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    else
      raise WorkerError.new(self.class, jid)
    end
  rescue => e
    if async
      message = e.message.truncate(150)
      logger.warn "#{e.class} #{message} #{user_id} #{uid}"
      logger.info e.backtrace.join "\n"
    else
      raise WorkerError.new(self.class, jid)
    end
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{twitter_user&.screen_name}"
  end
end
