class CreateSearchReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)

    messaging_uids = Util::MessagingUids.new(Redis.client)
    return if messaging_uids.exists?(user.uid)
    messaging_uids.add(user.uid)

    return unless user.authorized? && user.can_send_search?

    report = SearchReport.new(user_id: user.id, token: SearchReport.generate_token)
    message = report.build_message(html: false)

    # TODO Implement email
    # TODO Implement onesignal

    dm = user.api_client.create_direct_message(user.uid.to_i, message)

    ActiveRecord::Base.transaction do
      report.update!(message_id: dm.id)
      user.notification_setting.touch(:search_sent_at)
    end

  rescue => e
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    end

    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
  end
end
