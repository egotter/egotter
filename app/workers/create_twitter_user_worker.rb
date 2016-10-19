class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(values)
    user_id      = values['user_id'].to_i
    uid          = values['uid'].to_i
    log_attrs = {
      session_id:  values['session_id'],
      user_id:     user_id,
      uid:         uid,
      screen_name: values['screen_name'],
      bot_uid:     -100,
      auto:        values['auto'],
      via:         values['via'],
      device_type: values['device_type'],
      os:          values['os'],
      browser:     values['browser'],
      user_agent:  values['user_agent'],
      referer:     values['referer'],
      channel:     values['channel'],
    }
    user = User.find_by(id: user_id)
    client = user.nil? ? Bot.api_client : user.api_client
    log_attrs.update(bot_uid: client.verify_credentials.id)

    existing_tu = TwitterUser.latest(uid)
    if existing_tu.present? && existing_tu.fresh?
      existing_tu.increment(:search_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: "[#{existing_tu.id}] is recently created.")
      notify(user, existing_tu) unless user.nil?
      return
    end

    new_tu = TwitterUser.build_with_relations(client.user(uid), client: client, login_user: user, context: :search)
    new_tu.user_id = user.id
    if new_tu.save
      new_tu.increment(:search_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu) unless user.nil?
      return
    end

    if existing_tu.present?
      existing_tu.increment(:search_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed.")
      notify(user, existing_tu) unless user.nil?
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

  def notify(login_user, tu)
    searched_user = User.find_by(uid: tu.uid)
    return if searched_user.nil?

    url = Rails.application.routes.url_helpers.search_url(screen_name: tu.screen_name, id: tu.uid, medium: 'dm')

    unless login_user.id == searched_user.id
      CreateNotificationMessageWorker.perform_async(
        user_id:     login_user.id,
        uid:         tu.uid,
        screen_name: tu.screen_name,
        message:     I18n.t('dictionary.you_are_searched', kaomoji: Kaomoji.unhappy, url: url),
        medium:      'dm'
      )

      # TODO implement
      CreateNotificationMessageWorker.perform_async(
        user_id:     login_user.id,
        uid:         tu.uid,
        screen_name: tu.screen_name,
        headings:    {en: I18n.t('onesignal.searchNotification.title', locale: :en), ja: I18n.t('onesignal.searchNotification.title', locale: :ja)}
        contents:    {en: I18n.t('onesignal.searchNotification.message', locale: :en), ja: I18n.t('onesignal.searchNotification.message', locale: :ja)}
        medium:      'onesignal'
      )
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.id} #{tu.inspect}"
  end

  def create_log(status, attrs, call_count: -1, reason: '', message: '')
    BackgroundSearchLog.create!(
      session_id:  attrs[:session_id],
      user_id:     attrs[:user_id],
      uid:         attrs[:uid],
      screen_name: attrs[:screen_name],
      bot_uid:     attrs[:bot_uid],
      auto:        attrs[:auto],
      status:      status,
      reason:      reason,
      message:     message,
      call_count:  call_count,
      via:         attrs[:via],
      device_type: attrs[:device_type],
      os:          attrs[:os],
      browser:     attrs[:browser],
      user_agent:  attrs[:user_agent],
      referer:     attrs[:referer],
      channel:     attrs[:channel],
    )
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{status} #{attrs.inspect} #{reason} #{message}"
  end
end
