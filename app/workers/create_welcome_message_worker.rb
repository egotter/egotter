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
  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
