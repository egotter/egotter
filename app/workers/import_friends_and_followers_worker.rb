class ImportFriendsAndFollowersWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid, options = {})
    started_at = Time.zone.now
    client = ApiClient.user_or_bot_client(user_id)
    async = options.fetch('async', true)

    user = TwitterDB::User.builder(uid).client(client).build
    user.persist!

  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id, uid: uid)
    raise WorkerError.new(self.class, jid) unless async
  rescue ActiveRecord::StatementInvalid => e
    if async
      logger.warn "Deadlock found #{user_id} #{uid} start: #{short_hour(started_at)} finish: #{short_hour(Time.zone.now)}"
      logger.info e.backtrace.grep_v(/\.bundle/).join "\n"
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
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid}"
  end
end
