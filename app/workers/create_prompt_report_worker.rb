class CreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)

    return if Util::MessagingRequests.exists?(user.uid)
    Util::MessagingRequests.add(user.uid)

    log = CreatePromptReportLog.new(
      user_id: user.id,
      uid: user.uid,
      screen_name: user.screen_name,
      bot_uid: user.uid,
      status: false,
      call_count: -1
    )
    client = user.api_client

    unless user.authorized? && user.can_send_dm? && user.active?(14)
      return log.update!(message: "authorized: #{user.authorized?}, can_send_dm: #{user.can_send_dm?}, active: #{user.active?(14)}")
    end

    twitter_user = (user.last_access_at ? TwitterUser.till(user.last_access_at) : TwitterUser).latest(user.uid.to_i)
    if twitter_user.nil?
      # TODO Create TwitterUser
      return log.update!(message: 'No TwitterUser')
    end

    if twitter_user.friendless?
      return log.update!(message: 'Too many friends')
    end

    t_user = client.user(user.uid.to_i)
    if t_user[:suspended]
      return log.update!(message: 'Suspended')
    end

    new_tu = TwitterUser.build_by_user(t_user)
    changes = twitter_user.diff(new_tu, only: %i(followers_count))

    if changes.empty?
      return log.update!(message: 'followers_count not changed')
    end

    if changes[:followers_count][0] <= changes[:followers_count][1]
      return log.update!(message: 'followers_count increased')
    end

    old_report = PromptReport.latest(user.id)
    if old_report && changes == JSON.parse(old_report.changes_json, symbolize_names: true)
      return log.update!(message: 'Message not changed')
    end

    # TODO Implement email
    # TODO Implement onesignal

    begin
      PromptReport.you_are_removed(user.id, changes_json: changes.to_json).deliver
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
      return log.update!(message: 'Creating DM failed')
    end

    log.update!(status: true, message: 'ok')
  rescue => e
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    end

    logger.warn "#{e.class}: #{e.message.truncate(150)} #{user_id}"
    log.update!(message: e.message.truncate(150))
  end
end
