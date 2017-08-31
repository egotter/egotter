class DeleteForbiddenUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(screen_name)
    ForbiddenUser.find_by(screen_name: screen_name)&.delete
  rescue ActiveRecord::RecordNotUnique => e
    logger.info e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{screen_name}"
  end
end
