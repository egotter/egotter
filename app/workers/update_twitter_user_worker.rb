class UpdateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id)
    client = Hashie::Mash.new({call_count: -100}) # If an error happens, This client is used in rescue block.
    user = User.find(user_id)
    uid = user.uid.to_i
    log = BackgroundUpdateLog.new(
      user_id:     user.id,
      uid:         uid,
      screen_name: user.screen_name,
      bot_uid:     user.uid
    )
    client = user.api_client
    Rollbar.scope!(person: {id: user.id, username: user.screen_name, email: ''})

    unless user.authorized?
      log.update(status: false, message: "[#{user.screen_name}] is not authorized.")
      return
    end

    unless user.can_send?(:update)
      log.update(status: false, message: "[#{user.screen_name}] don't allow update notification.")
      return
    end

    if user.last_access_at && user.last_access_at < 14.days.ago
      log.update(status: false, message: "[#{user.screen_name}] has been MIA.")
      return
    end

    existing_tu = TwitterUser.with_friends.latest(uid)
    if existing_tu.present? && existing_tu.fresh?
      existing_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
      notify(user, existing_tu)
      return
    end

    new_tu = TwitterUser.build_with_relations(client.user(uid), client: client, login_user: user, context: :update)
    new_tu.user_id = user.id
    if new_tu.friendless?
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.screen_name}] has too many friends.")
      return
    end

    if new_tu.save
      new_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu)
      return
    end

    if existing_tu.present?
      existing_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed.")
      notify(user, existing_tu)
      return
    end

    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{new_tu.errors.full_messages.join(', ')}."
    )
    Rollbar.warn(e) # TODO NameError undefined local variable or method `e'
  rescue Twitter::Error::TooManyRequests => e
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::TooManyRequests::MESSAGE,
      message: ''
    )
    Rollbar.warn(e)
  rescue Twitter::Error::Unauthorized => e
    user.update(authorized: false)
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE,
      message: ''
    )
    Rollbar.warn(e)
  rescue ActiveRecord::StatementInvalid, Mysql2::Error, Twitter::Error::RequestTimeout, Twitter::Error::Forbidden, Twitter::Error::ServiceUnavailable, Twitter::Error => e
    # ActiveRecord::StatementInvalid Mysql2::Error: Lost connection to MySQL server during query: {SQL}
    # ActiveRecord::StatementInvalid: Mysql2::Error: MySQL server has gone away: {SQL}
    # Mysql2::Error: MySQL server has gone away
    # Twitter::Error::RequestTimeout Net::ReadTimeout
    # Twitter::Error Net::OpenTimeout
    # Twitter::Error Connection reset by peer - SSL_connect
    # Twitter::Error::Forbidden To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.
    # Twitter::Error::Forbidden Your account is suspended and is not permitted to access this feature.
    # Twitter::Error::ServiceUnavailable
    # Twitter::Error::ServiceUnavailable Over capacity
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    raise e
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message}"
    )
    Rollbar.warn(e)
  end

  def notify(login_user, tu)
    CreatePageCacheWorker.perform_async(tu.uid)

    %w(dm onesignal).each do |medium|
      CreateNotificationMessageWorker.perform_async(login_user.id, tu.uid.to_i, tu.screen_name, type: 'update', medium: medium)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.inspect} #{tu.inspect}"
    Rollbar.warn(e)
  end
end
