class CreateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    message = NotificationMessage.create!(attrs)
    user = User.find(message.user_id)

    if user.notification.can_send_search?
      user.api_client.create_direct_message(user.uid.to_i, message.message)
      user.notification.update(last_search_at: Time.zone.now)
      logger.warn "true #{attrs.inspect}"
    else
      logger.warn "false #{attrs.inspect}"
    end

  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end
end
