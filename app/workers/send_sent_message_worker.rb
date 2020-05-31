class SendSentMessageWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  #   text
  #   dm_id
  def perform(recipient_uid, options = {})
    return if fixed_message?(options['text'])
    send_message_to_slack(recipient_uid, options['dm_id'], options['text'])
  rescue => e
    notify_airbrake(e, recipient_uid: recipient_uid, options: options)
  end

  def fixed_message?(text)
    text == I18n.t('quick_replies.prompt_reports.label3')
  end

  def send_message_to_slack(recipient_uid, dm_id, text)
    user = User.find_by(uid: recipient_uid)
    screen_name = user ? user.screen_name : (Bot.api_client.user(recipient_uid)[:screen_name] rescue recipient_uid)

    text = dm_url(screen_name) + "\n" + text
    text = error_check(user.id) + "\n" + text if user

    SlackClient.sent_messages.send_message(text, title: "`#{screen_name}`")
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
    notify_airbrake(e, recipient_uid: recipient_uid, text: text)
  end

  def dm_url(screen_name)
    "https://twitter.com/direct_messages/create/#{screen_name}"
  end

  def error_check(user_id)
    CreatePromptReportRequest.new(user_id: user_id).error_check!
    'success'
  rescue => e
    e.class.to_s
  end
end
