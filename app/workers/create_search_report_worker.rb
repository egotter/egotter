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

    report = SearchReport.new(user_id: user.id, token: SearchReport.generate_token)
    message = report.build_message(format: 'text')

    # TODO Implement email
    # TODO Implement onesignal

    dm = user.api_client.twitter.create_direct_message(user.uid.to_i, message)

    ActiveRecord::Base.transaction do
      report.update!(message_id: dm.id)
      user.notification_setting.update!(search_sent_at: Time.zone.now)
    end

  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id)
  rescue Twitter::Error::Forbidden => e
    handle_forbidden_exception(e, user_id: user_id)
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(150)} #{user_id}"
  end
end
