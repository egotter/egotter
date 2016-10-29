class UpdateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    notification = NotificationMessage.order(created_at: :desc).find_by(token: attrs['token'], medium: attrs['medium'], read: false)
    if notification
      notification.update!(read: true, read_at: attrs['read_at'])
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end
end
