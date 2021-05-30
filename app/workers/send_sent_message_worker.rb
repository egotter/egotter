class SendSentMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  #   text
  #   dm_id
  def perform(recipient_uid, options = {})
    return if static_message?(options['text'])
    send_message_to_slack(recipient_uid, options['text'])
  rescue => e
    logger.warn "Sending a message to slack failed #{e.inspect}"
  end

  def static_message?(text)
    text == I18n.t('quick_replies.prompt_reports.label3') ||
        text.include?('#egotter')
  end

  def send_message_to_slack(recipient_uid, text)
    screen_name = fetch_screen_name(recipient_uid)
    text = dm_url(screen_name) + "\n" + text
    SlackClient.sent_messages.send_message(text, title: "`#{screen_name}` `#{recipient_uid}`")
  end

  def fetch_screen_name(uid)
    user = User.find_by(uid: uid)
    user ? user.screen_name : (Bot.api_client.user(uid)[:screen_name] rescue uid)
  end

  def dm_url(screen_name)
    "https://twitter.com/direct_messages/create/#{screen_name}"
  end
end
