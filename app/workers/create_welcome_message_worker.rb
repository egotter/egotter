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

    dm = nil
    begin
      dm = WelcomeMessage.welcome(user.id).deliver!
    rescue => e
      send_message_to_slack(e.message, title: e.class)
      raise
    else
      send_message_to_slack(dm.text, title: 'OK')
    end
  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def send_message_to_slack(text, title: nil)
    SlackClient.welcome_messages.send_message(text, title: "`#{title}`")
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
  end
end
