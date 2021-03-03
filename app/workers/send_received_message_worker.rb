class SendReceivedMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  #   text
  #   dm_id
  def perform(sender_uid, options = {})
    return if dont_send_message?(options['text'])
    send_message(sender_uid, options['text'])
  rescue => e
    logger.warn "sender_uid=#{sender_uid} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  QUICK_REPLIES = [
      /\A【?#{I18n.t('quick_replies.followed.label')}】?\z/,
      /\A【?#{I18n.t('quick_replies.welcome_messages.label1')}】?\z/,
      /\A【?#{I18n.t('quick_replies.welcome_messages.label2')}】?\z/,
      /\A【?初期設定(\s|　)*開始】?\z/,
      /\A【?#{I18n.t('quick_replies.search_reports.label1')}】?\z/,
      /\A【?#{I18n.t('quick_replies.search_reports.label2')}】?\z/,
      /\A【?#{I18n.t('quick_replies.search_reports.label3')}】?\z/,
      /\A【?#{I18n.t('quick_replies.search_reports.label4')}】?\z/,
      /\A【?#{I18n.t('quick_replies.block_reports.label1')}】?\z/,
      /\A【?#{I18n.t('quick_replies.block_reports.label2')}】?\z/,
      /\A【?#{I18n.t('quick_replies.block_reports.label3')}】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label1')}】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label4')}】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label2')}】?\z/,
      /\A【?アクセス通知(\s|　)*届きました】?\z/,
      /\A【?#{I18n.t('quick_replies.shared.label3')}】?\z/,
      /\A【?フォロー通知(\s|　)*届きました】?\z/,
  ]

  def dont_send_message?(text)
    PeriodicReportResponder::Processor.new(nil, text).received? ||
        BlockReportResponder::Processor.new(nil, text).received? ||
        MuteReportResponder::Processor.new(nil, text).received? ||
        SpamMessageConcern::SpamMessageProcessor.new(nil, text).received? ||
        QUICK_REPLIES.any? { |regexp| regexp.match?(text) } ||
        text == '今すぐ' ||
        text == 'あ' ||
        text == 'は' ||
        text == 'り'
  end

  private

  def send_message(sender_uid, text)
    user = TwitterDB::User.find_by(uid: sender_uid)
    screen_name = user&.screen_name
    icon_url = user&.profile_image_url_https
    urls = [dm_url(screen_name), dm_url_by_uid(sender_uid)]

    begin
      SlackClient.channel('received_messages').send_context_message(text, screen_name, icon_url, urls)
    rescue => e
      SlackClient.channel('received_messages').send_message("sender_uid=#{sender_uid} text=#{text}")
    end

    if recently_tweets_deleted_user?(sender_uid)
      begin
        SlackClient.channel('delete_tweets').send_context_message(text, screen_name, icon_url, urls)
      rescue => e
        SlackClient.channel('delete_tweets').send_message("sender_uid=#{sender_uid} text=#{text}")
      end
    end
  end

  def dm_url(screen_name)
    "https://twitter.com/direct_messages/create/#{screen_name}"
  end

  def dm_url_by_uid(uid)
    "https://twitter.com/messages/#{User::EGOTTER_UID}-#{uid}"
  end

  def recently_tweets_deleted_user?(uid)
    (user = User.find_by(uid: uid)) && DeleteTweetsRequest.order(created_at: :desc).limit(10).pluck(:user_id).include?(user.id)
  end
end
