class ResetTooManyFriendsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(user_id)
    TooManyFriendsUsers.new.delete(user_id)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id}"
  end
end
