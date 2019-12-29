class CreateAnswerMessageWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def perform(sender_uid, options = {})
    send_message_to_slack(sender_uid, options['text'])
  rescue => e
    notify_airbrake(e, sender_uid: sender_uid, options: options)
  end

  def send_message_to_slack(sender_uid, text)
    name = (Bot.api_client.user(sender_uid)[:screen_name] rescue sender_uid)
    SlackClient.answer_messages.send_message(text, title: "`#{name}`")
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
    notify_airbrake(e, sender_uid: sender_uid, text: text)
  end
end
