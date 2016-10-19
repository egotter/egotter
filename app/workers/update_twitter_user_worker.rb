class UpdateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    uid = user.uid.to_i
    log_attrs = {
      user_id:     user.id,
      uid:         uid,
      screen_name: user.screen_name,
      bot_uid:     user.uid,
    }
    client = user.api_client

    existing_tu = TwitterUser.latest(uid)
    if existing_tu.present? && existing_tu.fresh?
      existing_tu.increment(:update_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
      notify(user, existing_tu, changed: false)
      return
    end

    new_tu = TwitterUser.build_with_relations(client.user(uid), client: client, login_user: user, context: :update)
    new_tu.user_id = user.id
    if new_tu.save
      new_tu.increment(:update_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu, changed: true)
      return
    end

    if existing_tu.present?
      existing_tu.increment(:update_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed.")
      notify(user, existing_tu, changed: false)
      return
    end

    create_log(
      false,
      log_attrs,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{new_tu.errors.full_messages.join(', ')}."
    )
  rescue Twitter::Error::TooManyRequests => e
    create_log(
      false,
      log_attrs,
      call_count: client.call_count,
      reason: BackgroundSearchLog::TooManyRequests::MESSAGE
    )
  rescue Twitter::Error::Unauthorized => e
    create_log(
      false,
      log_attrs,
      call_count: client.call_count,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE
    )
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    logger.info e.backtrace.slice(0, 10).join("\n")
    create_log(
      false,
      log_attrs,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message}"
    )
  end

  def notify(login_user, tu, changed:)
    url = Rails.application.routes.url_helpers.search_url(screen_name: tu.screen_name, id: tu.uid, medium: 'dm')
    message =
      if changed
        "データの更新が完了しました。フォロー・フォロワーに変更があります。 #egotter #{url}"
      else
        "データの更新が完了しました。フォロー・フォロワーに変更はありません。 #egotter #{url}"
      end

    ::Cache::PageCache.new.delete(tu.uid)

    CreateNotificationMessageWorker.perform_async(
      user_id:     login_user.id,
      uid:         tu.uid,
      screen_name: tu.screen_name,
      message:     message,
      medium:      'dm'
    )

    url = Rails.application.routes.url_helpers.search_url(screen_name: tu.screen_name, id: tu.uid, medium: 'onesignal')

    # TODO implement
    CreateNotificationMessageWorker.perform_async(
      user_id:     login_user.id,
      uid:         tu.uid,
      screen_name: tu.screen_name,
      headings:    {en: I18n.t('onesignal.updateNotification.title', user: tu.mention_name, locale: :en), ja: I18n.t('onesignal.updateNotification.title', user: tu.mention_name, locale: :ja)},
      contents:    {en: I18n.t('onesignal.updateNotification.message', url: url, locale: :en), ja: I18n.t('onesignal.updateNotification.message', url: url, locale: :ja)},
      medium:      'onesignal'
    )
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.inspect} #{tu.inspect} #{changed}"
  end

  def create_log(status, attrs, call_count: -1, reason: '', message: '')
    BackgroundUpdateLog.create!(
      user_id:     attrs[:user_id],
      uid:         attrs[:uid],
      screen_name: attrs[:screen_name],
      bot_uid:     attrs[:bot_uid],
      status:      status,
      reason:      reason,
      message:     message,
      call_count:  call_count,
    )
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{status} #{attrs.inspect} #{reason} #{message}"
  end
end
