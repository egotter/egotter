class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(values)
    if !values['queued_at'] || !(Time.zone.parse(values['queued_at']) rescue nil)
      values['queued_at'] = Time.zone.now
      CreateTwitterUserWorker.perform_in(rand(30..300).minutes, values)
      return
    end

    queue = Sidekiq::Queue.new(self.class.to_s)

    if queue.size > 3 && Time.zone.parse(values['queued_at']) < 5.minutes.ago
      CreateTwitterUserWorker.perform_in(rand(30..300).minutes, values)
      return
    end

    client = Hashie::Mash.new({call_count: -100}) # If an error happens, This client is used in rescue block.
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
    user = User.find_by(id: user_id)
    client = user.nil? ? Bot.api_client : user.api_client
    log.bot_uid = client.verify_credentials.id

    if queue.size > 3 && log.auto
      log.update(status: false, call_count: client.call_count, message: "[#{uid}] is skipped because busy.")
      return after_perform(user_id, uid, '')
    end

    creating_uids = Util::CreatingUids.new(Redis.client)
    if creating_uids.exists?(uid)
      log.update(status: false, call_count: client.call_count, message: "[#{uid}] is recently creating.")
      return after_perform(user_id, uid, '')
    end
    creating_uids.add(uid)

    existing_tu = TwitterUser.latest(uid)
    if existing_tu&.fresh?
      existing_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
      notify(user, existing_tu)
      return after_perform(user_id, uid, existing_tu.screen_name)
    end

    new_tu = TwitterUser.build_by_user(client.user(uid))
    relations = TwitterUserFetcher.new(new_tu, client: client, login_user: user).fetch

    new_tu.build_friends_and_followers(relations)
    if existing_tu.present? && new_tu.friendless?
      existing_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: 'new record is friendless.')
      notify(user, existing_tu)
      return after_perform(user_id, uid, existing_tu.screen_name)
    end

    if existing_tu&.diff(new_tu)&.empty?
      existing_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed. (early)")
      notify(user, existing_tu)
      return after_perform(user_id, uid, existing_tu.screen_name)
    end

    new_tu.build_other_relations(relations)
    new_tu.user_id = user_id
    if new_tu.save
      ImportReplyingRepliedAndFavoritesWorker.perform_async(user_id, new_tu.uid.to_i)
      new_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu)
      return after_perform(user_id, uid, new_tu.screen_name)
    end

    if existing_tu.present?
      existing_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed.")
      notify(user, existing_tu)
      return after_perform(user_id, uid, existing_tu.screen_name)
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
    if user && e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    end
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE,
      message: ''
    )
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{self.class}##{__method__}: #{e.class} #{message} #{values.inspect}"
    logger.info e.backtrace.join("\n")
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{message}"
    )
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

  def after_perform(user_id, uid, screen_name)
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{screen_name}"
  end
end
