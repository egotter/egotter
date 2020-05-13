class CreateWelcomeMessageWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minutes
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    begin
      WelcomeMessage.welcome(user.id).deliver!
    rescue => e
      send_message_to_slack("#{e.inspect}", title: user_id)
      raise
    end
  rescue => e
    logger.info "sending welcome message is faield #{e.inspect} user_id=#{user_id}"
    notify_airbrake(e, user_id: user_id, options: options)
  end

  def send_message_to_slack(text, title: nil)
    SlackClient.welcome_messages.send_message(text, title: "`#{title}`")
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
  end
end
