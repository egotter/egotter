class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(values)
    user_id = values['user_id'].to_i
    uid = values['uid'].to_i
    screen_name = values['screen_name']
    url = values['url']
    client = User.exists?(user_id) ? User.find(user_id).api_client : Bot.api_client
    log_attrs = {
      session_id: values['session_id'],
      user_id: user_id,
      uid: uid,
      screen_name: screen_name,
      bot_uid: client.uid,
      device_type: values['device_type'],
      os: values['os'],
      browser: values['browser'],
      user_agent: values['user_agent'],
      referer: values['referer'],
    }

    if (existing_tu = TwitterUser.latest(uid, user_id)).present? && existing_tu.recently_created?
      existing_tu.search_and_touch
      create_success_log(
        'cannot create a new TwitterUser because a recently created record exists.',
        {call_count: client.call_count}.merge(log_attrs)
      )
      setup_notification_message_worker(user_id, uid, screen_name, url)
      return
    end

    new_tu = TwitterUser.build_with_relations(client.user(uid), user_id, client: client, context: 'search')
    if new_tu.save
      new_tu.search_and_touch
      create_success_log(
        'creates a new TwitterUser.',
        {call_count: client.call_count}.merge(log_attrs)
      )
      setup_notification_message_worker(user_id, uid, screen_name, url)
      return
    end

    if existing_tu.present?
      existing_tu.search_and_touch
      create_success_log(
        'cannot save a new TwitterUser because existing one is the same as new one.',
        {call_count: client.call_count}.merge(log_attrs)
      )
      setup_notification_message_worker(user_id, uid, screen_name, url)
      return
    end

    create_failed_log(
      BackgroundSearchLog::SomethingError::MESSAGE,
      "cannot save a new TwitterUser because of #{new_tu.errors.full_messages.join(', ')}.",
      {call_count: client.call_count}.merge(log_attrs)
    )
  rescue Twitter::Error::TooManyRequests => e
    create_failed_log(
      BackgroundSearchLog::TooManyRequests::MESSAGE, '',
      {call_count: client.call_count}.merge(log_attrs)
    )
  rescue Twitter::Error::Unauthorized => e
    create_failed_log(
      BackgroundSearchLog::Unauthorized::MESSAGE, '',
      {call_count: client.call_count}.merge(log_attrs)
    )
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    create_failed_log(
      BackgroundSearchLog::SomethingError::MESSAGE, "#{e.class} #{e.message}",
      {call_count: client.call_count}.merge(log_attrs)
    )
  end

  def setup_notification_message_worker(user_id, uid, screen_name, url)
    searched_user = User.find_by(uid: uid)
    return if searched_user.blank?

    if user_id == searched_user.id
      someone_searched_himself_or_herself(user_id, uid, screen_name, url)
    elsif user_id != searched_user.id
      someone_searched_existing_user(searched_user.id, uid, screen_name, url)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{user_id} #{uid} #{screen_name} #{url}"
  end

  # TODO Send a dm when removing or removed is updated.
  def someone_searched_himself_or_herself(user_id, uid, screen_name, url)
    # CreateNotificationMessageWorker.perform_async(
    #   user_id: user_id,
    #   uid: uid,
    #   screen_name: screen_name,
    #   message: I18n.t('dictionary.you_are_searched_by_himself', kaomoji: Kaomoji.happy, url: url)
    # )
  end

  def someone_searched_existing_user(user_id, uid, screen_name, url)
    CreateNotificationMessageWorker.perform_async(
      user_id: user_id,
      uid: uid,
      screen_name: screen_name,
      message: I18n.t('dictionary.you_are_searched', kaomoji: Kaomoji.unhappy, url: url)
    )
  end

  def create_success_log(message, attrs)
    BackgroundSearchLog.create!(
      session_id:  attrs[:session_id],
      user_id:     attrs[:user_id],
      uid:         attrs[:uid],
      screen_name: attrs[:screen_name],
      bot_uid:     attrs[:bot_uid],
      status:      true,
      reason:      '',
      message:     message,
      call_count:  attrs[:call_count],
      device_type: attrs[:device_type],
      os:          attrs[:os],
      browser:     attrs[:browser],
      user_agent:  attrs[:user_agent],
      referer:     attrs[:referer]
    )
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{message} #{attrs.inspect}"
  end

  def create_failed_log(reason, message, attrs)
    BackgroundSearchLog.create!(
      session_id:  attrs[:session_id],
      user_id:     attrs[:user_id],
      uid:         attrs[:uid],
      screen_name: attrs[:screen_name],
      bot_uid:     attrs[:bot_uid],
      status:      false,
      reason:      reason,
      message:     message,
      call_count:  attrs[:call_count],
      device_type: attrs[:device_type],
      os:          attrs[:os],
      browser:     attrs[:browser],
      user_agent:  attrs[:user_agent],
      referer:     attrs[:referer]
    )
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{reason} #{message} #{attrs.inspect}"
  end
end
