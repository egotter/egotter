class CreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    client = Hashie::Mash.new(call_count: -100)
    user = User.find(user_id)

    messaging_uids = Util::MessagingUids.new(Redis.client)
    return if messaging_uids.exists?(user.uid)
    messaging_uids.add(user.uid)

    log = CreatePromptReportLog.new(
      user_id:     user.id,
      uid:         user.uid.to_i,
      screen_name: user.screen_name,
      bot_uid:     user.uid.to_i,
      status:      false
    )
    client = user.api_client

    unless user.authorized? && user.can_send_dm? && user.active?(14)
      log.update!(call_count: client.call_count, message: "authorized: #{user.authorized?}, can_send_dm: #{user.can_send_dm?}, active: #{user.active?(14)}")
      return
    end

    twitter_user = (user.last_access_at ? TwitterUser.till(user.last_access_at) : TwitterUser).latest(user.uid.to_i)
    if twitter_user.nil?
      # TODO Create TwitterUser
      log.update!(call_count: client.call_count, message: 'No TwitterUser')
      return
    end

    # if twitter_user.fresh?
    #   log.update(status: false, call_count: client.call_count, message: "[#{twitter_user.id}] is recently updated.")
    #   return
    # end

    if twitter_user.friendless?
      log.update!(call_count: client.call_count, message: 'Too many friends')
      return
    end

    t_user = client.user(user.uid.to_i)
    if t_user.suspended
      log.update!(call_count: client.call_count, message: 'Suspended')
      return
    end

    new_tu = TwitterUser.build_by_user(t_user)
    changes = twitter_user.diff(new_tu, only: %i(followers_count))

    if changes.empty?
      log.update!(call_count: client.call_count, message: 'followers_count not changed')
      return
    end

    if changes[:followers_count][0] <= changes[:followers_count][1]
      log.update!(call_count: client.call_count, message: 'followers_count increased')
      return
    end

    old_report = PromptReport.latest(user.id)
    if changes == old_report&.changes
      log.update!(call_count: client.call_count, message: 'Message not changed')
      return
    end

    new_report = PromptReport.new(user_id: user.id, changes_json: changes.to_json, token: PromptReport.generate_token)
    message = new_report.build_message(html: false)
    dm = nil

    # TODO Implement email
    # TODO Implement onesignal

    begin
      dm = client.create_direct_message(user.uid.to_i, message)
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
      log.update!(call_count: client.call_count, message: 'Creating DM failed')
      return
    end

    begin
      ActiveRecord::Base.transaction do
        new_report.update!(message_id: dm.id)
        user.notification_setting.update!(last_dm_at: Time.zone.now)
      end
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
      log.update!(call_count: client.call_count, message: 'Updating records failed')
      return
    end

    log.update!(status: true, call_count: client.call_count, message: 'ok')
  rescue => e
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    end

    logger.warn "#{e.class}: #{e.message.truncate(150)} #{user_id}"
    log.update!(
      call_count: client.call_count,
      message: e.message.truncate(150)
    )
  end
end
