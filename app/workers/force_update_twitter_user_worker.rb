class ForceUpdateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(values)
    client = Hashie::Mash.new({call_count: -100}) # If an error happens, This client is used in rescue block.
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

    existing_tu = TwitterUser.latest(uid)
    if existing_tu&.fresh?
      existing_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
      notify(user, existing_tu, :none)
      return
    end

    new_tu = TwitterUser.build_by_user(client.user(uid))
    relations = TwitterUserFetcher.new(new_tu, client: client, login_user: user).fetch
    ImportFriendsAndFollowersWorker.perform_async(user_id, uid) if %i(friend_ids follower_ids).all? { |key| relations.has_key?(key) }

    new_tu.build_friends_and_followers(relations)
    if existing_tu&.diff(new_tu)&.empty?
      existing_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed. (early)")
      notify(user, existing_tu, :none)
      return
    end

    new_tu.build_other_relations(relations)
    new_tu.user_id = user.id
    if new_tu.save
      ImportReplyingRepliedAndFavoritesWorker.perform_async(user.id, new_tu.id)
      new_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu, :created)
      return
    end

    if existing_tu.present?
      existing_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed.")
      notify(user, existing_tu, :none)
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
    logger.warn "force update finished #{login_user.id} #{tu.id} #{tu.screen_name} #{context}"
    # CreatePageCacheWorker.perform_async(tu.uid)
    #
    # %w(dm onesignal).each do |medium|
    #   CreateNotificationMessageWorker.perform_async(login_user.id, tu.uid.to_i, tu.screen_name, type: 'update', medium: medium)
    # end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.inspect} #{tu.inspect}"
  end
end
