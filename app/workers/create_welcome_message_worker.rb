class CreateWelcomeMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  include ReportRetryHandler
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
      retry_current_report(user_id, options)
      return
    end

    send_direct_message(user, options)
  rescue => e
    Airbag.warn "#{e.class} #{e.message} user_id=#{user_id} options=#{options}"
    Airbag.info e.backtrace.join("\n")
  end

  def send_direct_message(user, options)
    message = WelcomeMessage.welcome(user.id)
    message.set_prefix_message(options['prefix']) if options['prefix']
    message.deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_current_report(user.id, options, exception: e)
    else
      error_message = "#{e.inspect} user_id=#{user.id} screen_name=#{user.screen_name} options=#{options.inspect}"
      SendMessageToSlackWorker.perform_async(:messages_welcome, error_message)
    end
  end
end
