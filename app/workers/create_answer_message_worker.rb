class CreateAnswerMessageWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def perform(sender_uid, options = {})
    send_message_to_slack(options['text'], title: sender_uid)
  rescue => e
    notify_airbrake(e, sender_uid: sender_uid, options: options)
  end

  def send_message_to_slack(text, title: nil)
    title = "`#{title}`"
    SlackClient.answer_messages.send_message(text, title: title)
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
    notify_airbrake(e, text: text, title: title)
  end
end
