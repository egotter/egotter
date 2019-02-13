class CreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    user = User.includes(:notification_setting).find(user_id)

    return if Util::MessagingRequests.exists?(user.uid)
    Util::MessagingRequests.add(user.uid)

    log = CreatePromptReportLog.new(
      user_id: user.id,
      uid: user.uid,
      screen_name: user.screen_name,
      bot_uid: user.uid,
      status: false,
      message: '',
      call_count: -1
    )
    client = user.api_client

    unless user.authorized? && user.can_send_dm? && user.active?(14)
      return log.update!(error_message: "authorized: #{user.authorized?}, can_send_dm: #{user.can_send_dm?}, active: #{user.active?(14)}")
    end

    return log.update!(error_message: "Couldn't find TwitterUser") unless TwitterUser.exists?(uid: user.uid)

    t_user = client.user(user.uid)
    return log.update!(error_message: 'Suspended') if t_user[:suspended]
    return log.update!(error_message: 'Too many friends') if TwitterUser.too_many_friends?(t_user, login_user: user)

    twitter_user = TwitterUser.till(user.last_access_at).latest_by(uid: user.uid) if user.last_access_at
    twitter_user = TwitterUser.latest_by(uid: user.uid) unless twitter_user
    return log.update!(error_message: 'Too many friends') if twitter_user.too_many_friends?(login_user: user)
    return log.update!(error_message: 'Friendless') if twitter_user.no_need_to_import_friendships?

    friend_uids, follower_uids = TwitterUser::Batch.fetch_friend_ids_and_follower_ids(user.uid, client: client)
    return log.update!(error_message: "Couldn't fetch friend_ids or follower_ids") if friend_uids.nil? || follower_uids.nil?
    return log.update!(error_message: 'Unfollowers not increased') unless unfollowers_increased?(twitter_user, friend_uids, follower_uids)

    changes = {followers_count: [twitter_user.followerships.size, follower_uids.size]}

    old_report = PromptReport.latest(user.id)
    if old_report && changes == JSON.parse(old_report.changes_json, symbolize_names: true)
      return log.update!(error_message: 'Message not changed')
    end

    # TODO Implement email
    # TODO Implement onesignal

    begin
      dm = PromptReport.you_are_removed(user.id, changes_json: changes.to_json).deliver
    rescue Twitter::Error::Forbidden => e
      if e.message == 'You cannot send messages to users you have blocked.'
        # Don't update User#authorized to false because the case that the user don't disable tokens is possible.
        return log.update!(error_message: "egotter is blocked.")
      else
        logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
        return log.update!(error_message: "Couldn't create DM")
      end
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message.truncate(150)} #{user_id}"
      return log.update!(error_message: "Couldn't create DM")
    end

    log.update!(status: true, message: dm.text.remove(/\R/).gsub(%r{https?://[\S]+}, 'URL').truncate(300))
  rescue => e
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
      log.update!(error_message: e.message)
    else
      message = e.message.truncate(150)
      logger.warn "#{self.class}##{__method__}: #{e.class} #{message} #{user_id}"
      log.update!(error_message: message)
    end
  end

  private

  def unfollowers_increased?(twitter_user, friend_uids, follower_uids)
    (twitter_user.followerships.pluck(:follower_uid) - follower_uids).any?
  end
end
