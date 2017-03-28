class ImportFriendsAndFollowersWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid, options = {})
    started_at = Time.zone.now
    client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client
    async = options.fetch('async', true)

    user = TwitterDB::User.builder(uid).client(client).build
    user.persist!

  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      User.find_by(id: user_id)&.update(authorized: false)
    end

    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    UNAUTHORIZED_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)

    raise Error, e unless async
  rescue ActiveRecord::StatementInvalid => e
    logger.warn "Deadlock found #{user_id} #{uid} start: #{short_hour(started_at)} finish: #{short_hour(Time.zone.now)}"
    logger.info e.backtrace.grep_v(/\.bundle/).join "\n"

    raise Error, e unless async
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"

    raise Error, e unless async
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid}"
  end

  private

  class Error < StandardError
    def initialize(ex)
      super("#{ex.class} #{ex.message.truncate(100)}")
    end
  end
end
