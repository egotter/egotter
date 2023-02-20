# TODO Rename to SendSentDirectMessageToSlackWorker
class SendSentMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  #   text
  #   dm_id
  def perform(recipient_uid, options = {})
    return if static_message?(options['text'])
    send_message(recipient_uid, options['text'])
  rescue => e
    Airbag.warn "Sending a message to slack failed #{e.inspect}"
  end

  def static_message?(text)
    text == I18n.t('quick_replies.prompt_reports.label3') ||
        text.match?(/\A#{CreateGreetingOkMessageWorker::MESSAGE}/) ||
        text.include?('#egotter')
  end

  def send_message(recipient_uid, text)
    client = SlackBotClient.channel('messages_sent')

    if (user = TwitterDB::User.find_by(uid: recipient_uid))
      screen_name = user.screen_name
      icon_url = user.profile_image_url_https
      client.post_context_message("#{recipient_uid} #{screen_name} #{text}", screen_name, icon_url, [])
    else
      client.post_message("#{recipient_uid} #{text}")
    end
  end
end
