# TODO Rename to SendReceivedDirectMessageToSlackWorker
class SendReceivedMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  #   text
  #   dm_id
  def perform(sender_uid, options = {})
    return if ignore?(options['text'])
    send_message(sender_uid, options['text'])
  rescue => e
    Airbag.exception e, sender_uid: sender_uid, options: options
  end

  QUICK_REPLIES = [
      /\A【?#{I18n.t('quick_replies.followed.label')}】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label1')}】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label4')}】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label2')}】?\z/,
      /\A【?アクセスしました】?\z/,
      /\A【?アクセス通知(\s|　)*届きました】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label3')}】?\z/,
      /\A【?フォロー通知(\s|　)*届きました】?\z/,
  ]

  def ignore?(text)
    PeriodicReportResponder::Processor.new(nil, text).received? ||
        BlockReportResponder::Processor.new(nil, text).received? ||
        MuteReportResponder::Processor.new(nil, text).received? ||
        SearchReportResponder::Processor.new(nil, text).received? ||
        DeleteTweetsMessageResponder::Processor.new(nil, text).received? ||
        WelcomeReportResponder::Processor.new(nil, text).received? ||
        SpamMessageResponder::Processor.new(nil, text).received? ||
        StopAllReportsResponder::Processor.new(nil, text).received? ||
        QUICK_REPLIES.any? { |regexp| regexp.match?(text) } ||
        text.include?('DM送信テスト ※そのまま送信') ||
        text.include?('送信】をDMにコピペして送ってください') ||
        text.include?('送ると、今すぐリムられ通知を受信することができます') ||
        text == 'あ' ||
        text == 'は' ||
        text == 'り'
  end

  private

  def send_message(sender_uid, text)
    client = SlackBotClient.channel('messages_received')

    if (user = TwitterDB::User.find_by(uid: sender_uid))
      screen_name = user.screen_name
      icon_url = user.profile_image_url_https
      client.post_context_message("#{sender_uid} #{screen_name} #{text}", screen_name, icon_url, [])
    else
      client.post_message("#{sender_uid} #{text}")
    end
  end

  def dm_url(screen_name)
    "https://twitter.com/direct_messages/create/#{screen_name}"
  end

  def dm_url_by_uid(uid)
    "https://twitter.com/messages/#{User::EGOTTER_UID}-#{uid}"
  end
end
