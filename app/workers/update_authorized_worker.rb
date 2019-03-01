class UpdateAuthorizedWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    t_user = user.api_client.verify_credentials

    user.assign_attributes(screen_name: t_user[:screen_name])
    user.save! if user.changed?
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      user.update!(authorized: false)
    else
      logger.warn "#{e.class}: #{e.message} #{user_id}"
      logger.info e.backtrace.join("\n")
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
    logger.info e.backtrace.join("\n")
  end
end
