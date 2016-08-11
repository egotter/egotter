class CreateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    message = NotificationMessage.create!(attrs)
    user = User.find(message.user_id)

    if user.notification_setting.can_send_search?
      user.api_client.create_direct_message(user.uid.to_i, message.message)
      user.notification_setting.update!(last_search_at: Time.zone.now)
      logger.warn "send: #{attrs.inspect}" # TODO remove debug code
    else
      logger.warn "cannot send: #{attrs.inspect}" # TODO remove debug code
    end

  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end
end
