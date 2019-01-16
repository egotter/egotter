class CreateSearchReportWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)

    return if Util::MessagingRequests.exists?(user.uid)
    Util::MessagingRequests.add(user.uid)

    return unless user.authorized? && user.can_send_search?

    # TODO Implement email
    # TODO Implement onesignal

    # It's possible that a user has logged in, but a record of TwitterUser doesn't exist.
    # In that case, user.twitter_user returns nil.
    return if !user.twitter_user || !user.twitter_user.twitter_db_user

    SearchReport.you_are_searched(user.id).deliver

  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id)
  rescue Twitter::Error::Forbidden => e
    handle_forbidden_exception(e, user_id: user_id)
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(150)} #{user_id}"
    logger.warn e.backtrace.join("\n")
  end
end
