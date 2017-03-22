class ForceUpdateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(values)
    client = Hashie::Mash.new(call_count: -100) # If an error happens, This client is used in rescue block.
    user_id      = values['user_id'].to_i
    uid          = values['uid'].to_i
    log = BackgroundForceUpdateLog.new(
      session_id:  values['session_id'],
      user_id:     user_id,
      uid:         uid,
      screen_name: values['screen_name'],
      action:      values['action'],
      bot_uid:     -100,
      via:         values['via'],
      device_type: values['device_type'],
      os:          values['os'],
      browser:     values['browser'],
      user_agent:  values['user_agent'],
      referer:     values['referer'],
      referral:    values['referral'],
      channel:     values['channel'],
      medium:      values['medium'],
    )
    user = User.find(user_id)
    client = user.api_client
    log.bot_uid = user.uid

    unless user.authorized?
      log.update(status: false, message: "[#{user.screen_name}] is not authorized.")
      return
    end

    builder = TwitterUser.builder(uid).client(client).login_user(user)
    new_tu = builder.build
    unless new_tu
      latest = TwitterUser.latest(uid)
      if latest
        latest.increment(:update_count).save
        notify(user, latest, :none)
        return log.update(status: true, call_count: client.call_count, message: builder.error_message)
      else
        return log.update(status: false, call_count: client.call_count, reason: BackgroundSearchLog::SomethingError::MESSAGE, message: builder.error_message)
      end
    end

    if new_tu.save
      new_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu, :created)
      return
    end

    latest = TwitterUser.latest(uid)
    if latest
      latest.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: 'not changed')
      notify(user, latest, :none)
      return
    end

    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{new_tu.errors.full_messages.join(', ')}."
    )
  rescue Twitter::Error::TooManyRequests => e
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::TooManyRequests::MESSAGE,
      message: ''
    )
  rescue Twitter::Error::Unauthorized => e
    user.update(authorized: false)
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE,
      message: ''
    )
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{values.inspect}"
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message}"
    )
  end

  private

  def notify(login_user, tu, context)
    # CreatePageCacheWorker.perform_async(tu.uid)
    #
    # %w(dm onesignal).each do |medium|
    #   CreateNotificationMessageWorker.perform_async(login_user.id, tu.uid.to_i, tu.screen_name, type: 'update', medium: medium)
    # end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.inspect} #{tu.inspect}"
  end
end
