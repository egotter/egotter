class CreateSearchReportWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)

    messaging_uids = Util::MessagingUids.new(Redis.client)
    return if messaging_uids.exists?(user.uid)
    messaging_uids.add(user.uid)

    return unless user.authorized? && user.can_send_search?

    # TODO Implement email
    # TODO Implement onesignal

    begin
      SearchReport.you_are_searched(user.id).deliver
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
    end

  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id)
  rescue Twitter::Error::Forbidden => e
    handle_forbidden_exception(e, user_id: user_id)
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(150)} #{user_id}"
  end
end
