class UpdateTwitterUserWorker
  include Sidekiq::Worker
  include Concerns::Rescue
  prepend Concerns::Perform
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    self.log = BackgroundUpdateLog.new(
      user_id:     user.id,
      uid:         user.uid.to_i,
      screen_name: user.screen_name,
      bot_uid:     user.uid.to_i
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

    existing_tu = TwitterUser.latest(user.uid.to_i)
    if existing_tu.present? && existing_tu.fresh?
      existing_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
      notify(user, existing_tu)
      return
    end

    new_tu = TwitterUser.build_with_relations(client.user(user.uid.to_i), client: client, login_user: user, context: :update)
    new_tu.user_id = user.id
    if new_tu.friendless?
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.screen_name}] has too many friends.")
      return
    end

    if new_tu.save
      new_tu.increment(:update_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu, created: true)
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
    Rollbar.warn(e)

  rescue Twitter::Error::Unauthorized => e
    user.update(authorized: false)
    raise e
  end

  def notify(login_user, tu, created: false)
    ::Cache::PageCache.new.delete(tu.uid) if created

    %w(dm onesignal).each do |medium|
      CreateNotificationMessageWorker.perform_async(login_user.id, tu.uid.to_i, tu.screen_name, type: 'update', medium: medium)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.inspect} #{tu.inspect}"
    Rollbar.warn(e)
  end
end
