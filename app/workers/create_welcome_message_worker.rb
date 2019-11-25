class CreateWelcomeMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    WelcomeMessage.welcome(user.id).deliver!

  # TODO Let's see how it goes.
  # rescue Twitter::Error::Unauthorized => e
  #   unless e.message == 'Invalid or expired token.'
  #     logger.warn "#{e.class}: #{e.message} #{user_id}"
  #     logger.info e.backtrace.join("\n")
  #   end
  # rescue Twitter::Error::Forbidden => e
  #   if e.message == 'You are sending a Direct Message to users that do not follow you.'
  #     logger.info "#{e.class}: #{e.message} #{user_id}"
  #   else
  #     logger.warn "#{e.class}: #{e.message} #{user_id}"
  #   end
  #   logger.info e.backtrace.join("\n")
  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{options.inspect}"
    logger.warn "Caused by #{e.inspect}" if e.cause
    logger.info e.backtrace.join("\n")
  end
end
