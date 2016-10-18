class CreateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    notification = NotificationMessage.new(attrs)
    user = User.find(notification.user_id)

    if user.notification_setting.can_send_search?
      user.api_client.create_direct_message(user.uid.to_i, notification.message)
      user.notification_setting.touch(:last_dm_at)
      notification.save!
    end

  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{attrs.inspect}"
  end
end
