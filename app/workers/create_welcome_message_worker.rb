class CreateWelcomeMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minutes
  end

  # options:
  #   prefix
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    if PeriodicReport.send_report_limited?(user.uid)
      logger.warn "Send welcome message later user_id=#{user_id}"
      CreateWelcomeMessageWorker.perform_in(1.hour, user_id, options.merge(delay: true))
      return
    end

    begin
      message = WelcomeMessage.welcome(user.id)
      message.set_prefix_message(options['prefix']) if options['prefix']
      message.deliver!
    rescue => e
      SendMessageToSlackWorker.perform_async(:welcome_messages, "#{e.inspect} screen_name=#{user.screen_name}", user_id)
    end
  rescue => e
    logger.info "#{e.inspect} user_id=#{user_id}"
  end
end
