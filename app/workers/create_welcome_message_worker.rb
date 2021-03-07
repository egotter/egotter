class CreateWelcomeMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
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
      retry_current_job(user_id, options)
      return
    end

    send_direct_message(user, options)
  rescue => e
    logger.warn "#{e.class} #{e.message} user_id=#{user_id} options=#{options}"
    logger.info e.backtrace.join("\n")
  end

  def send_direct_message(user, options)
    message = WelcomeMessage.welcome(user.id)
    message.set_prefix_message(options['prefix']) if options['prefix']
    message.deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_current_job(user.id, options, exception: e)
    else
      error_message = "#{e.inspect} user_id=#{user.id} screen_name=#{user.screen_name} options=#{options.inspect}"
      SendMessageToSlackWorker.perform_async(:welcome_messages, error_message)
    end
  end

  def retry_current_job(user_id, options, exception: nil)
    logger.add(exception ? Logger::WARN : Logger::INFO) { "#{self.class} will be performed again user_id=#{user_id} exception=#{exception.inspect}" }
    CreateWelcomeMessageWorker.perform_in(1.hour + rand(30).minutes, user_id, options)
  end
end
