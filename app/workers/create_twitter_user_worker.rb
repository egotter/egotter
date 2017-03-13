class CreateTwitterUserWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(values)
    client = Hashie::Mash.new(call_count: -100)
    log = BackgroundSearchLog.new(message: '')
    user = user_id = uid = nil
    queued_at = values['queued_at'] = Time.zone.parse(values['queued_at']) if values['queued_at'].is_a?(String)
    started_at = Time.zone.now

    return unless before_perform(values)

    user_id      = values['user_id'].to_i
    uid          = values['uid'].to_i
    log = BackgroundSearchLog.new(
      session_id:  values['session_id'],
      user_id:     user_id,
      uid:         uid,
      screen_name: values['screen_name'],
      action:      values['action'],
      bot_uid:     -100,
      auto:        values['auto'],
      message:     '',
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
    log.queued_at = queued_at if log.respond_to?(:queued_at) # TODO remove later
    log.started_at = started_at if log.respond_to?(:started_at) # TODO remove later

    user = User.find_by(id: user_id)
    if user&.unauthorized?
      return log.update(status: false, call_count: 0, reason: BackgroundSearchLog::Unauthorized::MESSAGE)
    end

    client = user.nil? ? Bot.api_client : user.api_client
    log.bot_uid = client.verify_credentials.id

    creating_uids = Util::CreatingUids.new(Redis.client)
    if creating_uids.exists?(uid)
      return log.update(status: false, call_count: client.call_count, message: "[#{uid}] is recently creating.")
    end
    creating_uids.add(uid)

    existing_tu = TwitterUser.latest(uid)
    if existing_tu&.fresh?
      existing_tu.increment(:search_count).save
      notify(user, existing_tu)
      return log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
    end

    new_tu = TwitterUser.build_by_user(client.user(uid))
    relations = TwitterUserFetcher.new(new_tu, client: client, login_user: user).fetch

    new_tu.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])
    if existing_tu.present? && new_tu.friendless?
      existing_tu.increment(:search_count).save
      notify(user, existing_tu)
      return log.update(status: true, call_count: client.call_count, message: 'new record is friendless.')
    end

    if existing_tu&.diff(new_tu)&.empty?
      existing_tu.increment(:search_count).save
      notify(user, existing_tu)
      return log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed. (early)")
    end

    new_tu.build_other_relations(relations)
    new_tu.user_id = user_id
    if new_tu.save
      ImportTwitterUserRelationsWorker.perform_async(user_id, uid)
      new_tu.increment(:search_count).save
      notify(user, new_tu)
      return log.update(status: true, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
    end

    if existing_tu.present?
      existing_tu.increment(:search_count).save
      notify(user, existing_tu)
      return log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed.")
    end

    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{new_tu.errors.full_messages.join(', ')}."
    )
  rescue Twitter::Error::Forbidden => e
    if e.message != 'Your account is suspended and is not permitted to access this feature.' && e.message != 'User has been suspended.' && !e.message.start_with?('To protect our users from spam and other malicious activity,')
      logger.warn "#{e.class} #{e.message} #{values.inspect}"
    end
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message.truncate(150)}"
    )
  rescue Twitter::Error::NotFound => e
    unless e.message == 'User not found.'
      logger.warn "#{e.class} #{e.message} #{values.inspect}"
    end
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message.truncate(150)}"
    )
  rescue Twitter::Error::TooManyRequests => e
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::TooManyRequests::MESSAGE
    )
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      user&.update(authorized: false)
    end
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE
    )
  rescue Twitter::Error => e
    retry if e.message == 'Connection reset by peer - SSL_connect'
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{values.inspect}"
    logger.info e.backtrace.join("\n")
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{message}"
    )
  rescue => e
    # ActiveRecord::ConnectionTimeoutError could not obtain a database connection within 5.000 seconds
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{values.inspect}"
    logger.info e.backtrace.join("\n")
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{message}"
    )
  ensure
    message = "[worker] #{self.class} finished. #{user_id} #{uid} queued_at: #{short_hour(queued_at)}, started_at: #{short_hour(started_at)}, finished_at: #{short_hour(Time.zone.now)}"
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

  BUSY_QUEUE_SIZE = 0

  def before_perform(values)
    if values['queued_at'] < 2.minutes.ago || (Sidekiq::Queue.new(self.class.to_s).size > BUSY_QUEUE_SIZE && values['auto'])
      DelayedCreateTwitterUserWorker.perform_async(values)
      false
    else
      true
    end
  end
end
