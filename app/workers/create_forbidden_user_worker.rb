class CreateForbiddenUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(screen_name)
    ForbiddenUser.create!(screen_name: screen_name)
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{screen_name}"
  end
end
