class SendReceivedMessageWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  #   text
  #   dm_id
  def perform(sender_uid, options = {})
    return if fixed_message?(options['text'])
    send_message_to_slack(sender_uid, options['dm_id'], options['text'])
  rescue => e
    notify_airbrake(e, sender_uid: sender_uid, options: options)
  end

  QUICK_REPLIES = [
      I18n.t('quick_replies.continue.label'),
      I18n.t('quick_replies.revive.label'),
      I18n.t('quick_replies.followed.label'),
      I18n.t('quick_replies.prompt_reports.label1'),
      I18n.t('quick_replies.prompt_reports.label2'),
      I18n.t('quick_replies.welcome_messages.label1'),
      I18n.t('quick_replies.welcome_messages.label2'),
  ]

  def fixed_message?(text)
    text == I18n.t('quick_replies.prompt_reports.label1') ||
        text == I18n.t('quick_replies.prompt_reports.label2') ||
        text == I18n.t('quick_replies.prompt_reports.label3') ||
        text == I18n.t('quick_replies.prompt_reports.label4') ||
        text == I18n.t('quick_replies.prompt_reports.label5') ||
        text.match?(Concerns::PeriodicReportConcern::SEND_NOW_REGEXP) ||
        text.match?(Concerns::PeriodicReportConcern::STOP_NOW_REGEXP) ||
        text.match?(Concerns::PeriodicReportConcern::RESTART_REGEXP) ||
        text.match?(Concerns::PeriodicReportConcern::RECEIVED_REGEXP) ||
        text.match?(Concerns::PeriodicReportConcern::CONTINUE_EXACT_REGEXP)
  end

  def send_message_to_slack(sender_uid, dm_id, text)
    user = User.find_by(uid: sender_uid)
    screen_name = user ? user.screen_name : (Bot.api_client.user(sender_uid)[:screen_name] rescue sender_uid)

    text = dm_url(screen_name) + "\n" + text
    text = error_check(user.id) + "\n" + text if user

    if QUICK_REPLIES.any? { |message| text.include?(message) }
      SlackClient.continue_notif_messages.send_message(text, title: "`#{screen_name}`")
    else
      SlackClient.received_messages.send_message(text, title: "`#{screen_name}`")
    end
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
    notify_airbrake(e, sender_uid: sender_uid, text: text)
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
