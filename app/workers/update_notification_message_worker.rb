class UpdateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    NotificationMessage.order(created_at: :desc).find_by(token: attrs['token'], read: false).update!(read: true, read_at: attrs['read_at'])
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end
end
