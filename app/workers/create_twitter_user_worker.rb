class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(values)
    user_id      = values['user_id'].to_i
    uid          = values['uid'].to_i
    url          = values['url']
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
    client = User.exists?(user_id) ? User.find(user_id).api_client : Bot.api_client
    log_attrs.update(bot_uid: client.verify_credentials.id)

    existing_tu = TwitterUser.latest(uid)
    if existing_tu.present? && existing_tu.fresh?
      existing_tu.increment(:search_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: 'Recently created record exists.')
      send_notification_message(user_id, existing_tu, url)
      return
    end

    new_tu = TwitterUser.build_with_relations(client.user(uid), client: client, login_user: User.find_by(id: user_id), context: :search)
    new_tu.user_id = user_id
    if new_tu.save
      new_tu.increment(:search_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: 'creates a new TwitterUser.')
      send_notification_message(user_id, new_tu, url)
      return
    end

    if existing_tu.present?
      existing_tu.increment(:search_count).save
      create_log(true, log_attrs, call_count: client.call_count, message: 'Existing one is the same as new one.')
      send_notification_message(user_id, existing_tu, url)
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

  def send_notification_message(login_user_id, tu, url)
    searched_user = User.find_by(uid: tu.uid)
    return if searched_user.nil?

    unless login_user_id == searched_user.id
      CreateNotificationMessageWorker.perform_async(
        user_id: login_user_id,
        uid: tu.uid,
        screen_name: tu.screen_name,
        message: I18n.t('dictionary.you_are_searched', kaomoji: Kaomoji.unhappy, url: url),
        medium: 'dm'
      )
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user_id} #{tu.inspect} #{url}"
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
