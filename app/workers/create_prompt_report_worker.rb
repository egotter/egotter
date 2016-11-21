class CreatePromptReportWorker
  include Sidekiq::Worker
  include Concerns::Rescue
  prepend Concerns::Perform
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    self.log = CreatePromptReportLog.new(
      user_id:     user.id,
      uid:         user.uid.to_i,
      screen_name: user.screen_name,
      bot_uid:     user.uid.to_i
    )
    self.client = user.api_client
    Rollbar.scope!(person: {id: user.id, username: user.screen_name, email: ''})

    unless user.authorized?
      log.update(status: false, call_count: client.call_count, message: "[#{user.screen_name}] is not authorized.")
      return
    end

    unless user.can_send?(:update)
      log.update(status: false, call_count: client.call_count, message: "[#{user.screen_name}] don't allow update notification.")
      return
    end

    existing_tu = TwitterUser.latest(user.uid.to_i)
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

    new_tu = TwitterUser.build_by_user(client.user(user.uid.to_i))
    if existing_tu.diff(new_tu, only: %i(followers_count)).any?
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is maybe changed.")
      notify(user, existing_tu)
    else
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is maybe not changed.")
    end
  end

  def notify(login_user, tu)
    %w(dm).each do |medium| # TODO implement onesignal
      CreateNotificationMessageWorker.perform_async(login_user.id, tu.uid.to_i, tu.screen_name, type: 'prompt_report', medium: medium)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.inspect} #{tu.inspect}"
    Rollbar.warn(e)
  end
end
