class CreateNotFoundUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(screen_name)
    NotFoundUser.create!(screen_name: screen_name)
  rescue ActiveRecord::RecordNotUnique => e
    logger.info e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{screen_name}"
    logger.info e.backtrace.join("\n")
  end
end
