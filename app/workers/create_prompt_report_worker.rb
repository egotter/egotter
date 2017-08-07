class CreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    client = Hashie::Mash.new(call_count: -100) # If an error happens, This client is used in rescue block.
    user = User.find(user_id)
    log = CreatePromptReportLog.new(
      user_id:     user.id,
      uid:         user.uid.to_i,
      screen_name: user.screen_name,
      bot_uid:     user.uid.to_i
    )
    client = user.api_client

    unless user.authorized?
      log.update(status: false, call_count: client.call_count, message: "[#{user.screen_name}] is not authorized.")
      return
    end

    unless user.can_send?(:update)
      log.update(status: false, call_count: client.call_count, message: "[#{user.screen_name}] don't allow update notification.")
      return
    end

    if user.last_access_at && user.last_access_at < 14.days.ago
      log.update(status: false, message: "[#{user.screen_name}] has been MIA.")
      return
    end

    existing_tu = (user.last_access_at ? TwitterUser.till(user.last_access_at) : TwitterUser).latest(user.uid.to_i)
    if existing_tu.blank?
      log.update(status: false, call_count: client.call_count, message: "[#{user.screen_name}] has no twitter_users.")
      return
    end

    if existing_tu.fresh?
      log.update(status: false, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
      return
    end

    if existing_tu.friendless?
      log.update(status: false, call_count: client.call_count, message: "[#{existing_tu.id}] has too many friends.")
      return
    end

    t_user = client.user(user.uid.to_i)
    if t_user.suspended
      log.update(status: false, call_count: client.call_count, message: "[#{user.screen_name}] is suspended.")
      return
    end

    new_tu = TwitterUser.build_by_user(t_user)
    diff = existing_tu.diff(new_tu, only: %i(followers_count))
    if diff.any? && diff[:followers_count][0] > diff[:followers_count][1]
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is maybe changed.")
      notify(user, existing_tu, changes: diff)
    else
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is maybe not changed.")
    end
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    end
    raise e
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message}"
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{message}"
    )

  end

  def notify(login_user, tu, changes:)
    # CreatePageCacheWorker.new.perform(tu.uid)

    %w(dm).each do |medium| # TODO implement onesignal
      CreateNotificationMessageWorker.perform_async(login_user.id, tu.uid.to_i, tu.screen_name, type: 'prompt_report', medium: medium, changes: changes)
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{login_user.inspect} #{tu.inspect}"
  end
end
