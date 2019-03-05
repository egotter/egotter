class CreateBlockedUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(uid, screen_name)
    BlockedUser.create!(uid: uid, screen_name: screen_name)
  rescue ActiveRecord::RecordNotUnique => e
    logger.info e.message.truncate(100)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{uid} #{screen_name}"
    logger.info e.backtrace.join("\n")
  end
end
