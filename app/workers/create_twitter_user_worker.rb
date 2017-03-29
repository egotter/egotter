class CreateTwitterUserWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  BUSY_QUEUE_SIZE = 0

  def perform(values = {})
    client = Hashie::Mash.new(call_count: 0)
    log = BackgroundSearchLog.new(message: '')
    user = user_id = uid = nil
    values['enqueued_at'] = Time.zone.parse(values['enqueued_at']) if values['enqueued_at'].is_a?(String)
    enqueued_at = values['enqueued_at']
    started_at = Time.zone.now

    if self.class == CreateTwitterUserWorker
      if enqueued_at < 1.minutes.ago || (Sidekiq::Queue.new(self.class.name).size > BUSY_QUEUE_SIZE && values['auto'])
        log = nil
        return DelayedCreateTwitterUserWorker.perform_async(values)
      end
    end

    user_id      = values['user_id'].to_i
    uid          = values['uid'].to_i

    log = BackgroundSearchLog.new(
      session_id:  values.fetch('session_id', ''),
      user_id:     user_id,
      uid:         uid,
      screen_name: values.fetch('screen_name', ''),
      action:      values.fetch('action', ''),
      bot_uid:     -100,
      auto:        values.fetch('auto', false),
      message:     '',
      via:         values.fetch('via', ''),
      device_type: values.fetch('device_type', ''),
      os:          values.fetch('os', ''),
      browser:     values.fetch('browser', ''),
      user_agent:  values.fetch('user_agent', ''),
      referer:     values.fetch('referer', ''),
      referral:    values.fetch('referral', ''),
      channel:     values.fetch('channel', ''),
      medium:      values.fetch('medium', ''),
    )
    log.enqueued_at = enqueued_at
    log.started_at = started_at

    user = User.find_by(id: user_id)
    if user&.unauthorized?
      return log.assign_attributes(status: false, reason: BackgroundSearchLog::Unauthorized::MESSAGE)
    end

    client =
      if user
        log.bot_uid = user.uid
        user.api_client
      else
        bot = Bot.sample
        log.bot_uid = bot.uid
        bot.api_client
      end

    creating_uids = Util::CreatingUids.new(Redis.client)
    if creating_uids.exists?(uid)
      if TwitterUser.exists?(uid: uid)
        return log.assign_attributes(status: true, message: "[#{uid}] is recently created.")
      else
        return log.assign_attributes(status: false, reason: BackgroundSearchLog::SomethingError::MESSAGE, message: "[#{uid}] is recently created.")
      end
    end
    creating_uids.add(uid)

    builder = TwitterUser.builder(uid).client(client).login_user(user)
    new_tu = builder.build
    unless new_tu
      latest = TwitterUser.latest(uid)
      if latest
        latest.increment(:search_count).save
        notify(user, latest)
        return log.assign_attributes(status: true, message: builder.error_message)
      else
        return log.assign_attributes(status: false, reason: BackgroundSearchLog::SomethingError::MESSAGE, message: builder.error_message)
      end
    end

    if new_tu.save
      new_tu.increment(:search_count).save
      notify(user, new_tu)
      return log.assign_attributes(status: true, message: "[#{new_tu.id}] is created.")
    end

    latest = TwitterUser.latest(uid)
    if latest
      latest.increment(:search_count).save
      notify(user, latest)
      return log.assign_attributes(status: true, message: 'not changed')
    end

    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{new_tu.errors.full_messages.join(', ')}."
    )
  rescue Twitter::Error::Forbidden => e
    message = "#{e.class} #{e.message} #{user_id} #{uid}"
    FORBIDDEN_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)

    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message.truncate(150)}"
    )
  rescue Twitter::Error::NotFound => e
    handle_not_found_exception(e, user_id: user_id, uid: uid)

    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message.truncate(150)}"
    )
  rescue Twitter::Error::TooManyRequests => e
    log.update(
      status: false,
      reason: BackgroundSearchLog::TooManyRequests::MESSAGE
    )

    handle_retryable_exception(values, e)
  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id, uid: uid)

    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE
    )
  rescue Twitter::Error::InternalServerError, Twitter::Error::ServiceUnavailable => e
    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message}"
    )

    handle_retryable_exception(values, e)
  rescue Twitter::Error => e
    retry if e.message == 'Connection reset by peer - SSL_connect'

    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{values.inspect}"
    logger.info e.backtrace.join("\n")

    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{message}"
    )
  rescue => e
    # ActiveRecord::ConnectionTimeoutError could not obtain a database connection within 5.000 seconds
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{values.inspect}"
    logger.info e.backtrace.join("\n")

    log.assign_attributes(
      status: false,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{message}"
    )
  ensure
    log.update(call_count: client.call_count, finished_at: Time.zone.now) if log
    message = "[worker] #{self.class} finished. #{user_id} #{uid} enqueued_at: #{short_hour(enqueued_at)}, started_at: #{short_hour(started_at)}, finished_at: #{short_hour(Time.zone.now)}"
    Rails.logger.info message
    logger.info message
  end

  private

  def notify(login_user, tu)
    searched_user = User.find_by(uid: tu.uid)
    return if searched_user.nil?

    if login_user.nil? || login_user.id != searched_user.id
      %w(dm onesignal).each do |medium|
        CreateNotificationMessageWorker.perform_async(searched_user.id, tu.uid.to_i, tu.screen_name, type: 'search', medium: medium)
      end
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.id} #{tu.inspect}"
  end

  def handle_retryable_exception(values, ex)
    retry_jid = DelayedCreateTwitterUserWorker.perform_async(values)

    if ex.class == Twitter::Error::TooManyRequests
      logger.warn "#{ex.message} Reset in #{ex&.rate_limit&.reset_in} seconds #{values['user_id']} #{values['uid']} #{retry_jid}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
    else
      logger.warn "#{ex.message} #{values['user_id']} #{values['uid']} #{retry_jid}"
    end
  end
end
