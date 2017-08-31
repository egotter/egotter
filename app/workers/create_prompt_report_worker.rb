class CreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    client = Hashie::Mash.new(call_count: -100)
    user = User.find(user_id)

    return if Util::MessagingRequests.exists?(user.uid)
    Util::MessagingRequests.add(user.uid)

    log = CreatePromptReportLog.new(
      user_id:     user.id,
      uid:         user.uid.to_i,
      screen_name: user.screen_name,
      bot_uid:     user.uid.to_i,
      status:      false
    )
    client = user.api_client

    unless user.authorized? && user.can_send_dm? && user.active?(14)
      log.update!(call_count: -1, message: "authorized: #{user.authorized?}, can_send_dm: #{user.can_send_dm?}, active: #{user.active?(14)}")
      return
    end

    twitter_user = (user.last_access_at ? TwitterUser.till(user.last_access_at) : TwitterUser).latest(user.uid.to_i)
    if twitter_user.nil?
      # TODO Create TwitterUser
      log.update!(call_count: -1, message: 'No TwitterUser')
      return
    end

    # if twitter_user.fresh?
    #   log.update(status: false, call_count: -1, message: "[#{twitter_user.id}] is recently updated.")
    #   return
    # end

    if twitter_user.friendless?
      log.update!(call_count: -1, message: 'Too many friends')
      return
    end

    t_user = client.user(user.uid.to_i)
    if t_user[:suspended]
      log.update!(call_count: -1, message: 'Suspended')
      return
    end

    new_tu = TwitterUser.build_by_user(t_user)
    changes = twitter_user.diff(new_tu, only: %i(followers_count))

    if changes.empty?
      log.update!(call_count: -1, message: 'followers_count not changed')
      return
    end

    if changes[:followers_count][0] <= changes[:followers_count][1]
      log.update!(call_count: -1, message: 'followers_count increased')
      return
    end

    old_report = PromptReport.latest(user.id)
    if old_report && changes == JSON.parse(old_report.changes_json, symbolize_names: true)
      log.update!(call_count: -1, message: 'Message not changed')
      return
    end

    # TODO Implement email
    # TODO Implement onesignal

    begin
      PromptReport.you_are_removed(user.id, changes_json: changes.to_json).deliver
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
      log.update!(call_count: -1, message: 'Creating DM failed')
      return
    end

    log.update!(status: true, call_count: -1, message: 'ok')
  rescue => e
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    end

    logger.warn "#{e.class}: #{e.message.truncate(150)} #{user_id}"
    log.update!(
      call_count: -1,
      message: e.message.truncate(150)
    )
  end
end
