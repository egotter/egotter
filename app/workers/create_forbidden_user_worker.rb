class CreateForbiddenUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(screen_name)
    ForbiddenUser.create!(screen_name: screen_name)
  rescue ActiveRecord::RecordNotUnique => e
    logger.warn e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{screen_name}"
  end
end
