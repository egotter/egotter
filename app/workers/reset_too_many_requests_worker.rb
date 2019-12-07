class ResetTooManyRequestsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    TooManyRequestsUsers.new.delete(user_id)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id}"
  end
end
