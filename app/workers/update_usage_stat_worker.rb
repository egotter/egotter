class UpdateUsageStatWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def expire_in
    10.minutes
  end

  def perform(uid, options = {})
    stat = UsageStat.find_by(uid: uid)
    return if stat&.fresh?

    twitter_user = TwitterUser.select(:uid, :screen_name).latest_by(uid: uid)
    statuses =
      if twitter_user.statuses.exists?
        twitter_user.statuses
      else
        user = User.find_by(id: options['user_id'])
        user = User.authorized.find_by(uid: uid) unless user
        client = user ? user.api_client : Bot.api_client
        client.user_timeline(uid.to_i).map { |s| TwitterDB::Status.build_by(twitter_user: twitter_user, status: s) }
      end

    if statuses.any?
      UsageStat.builder(uid).statuses(statuses).build.save!
    end
  rescue Twitter::Error::Unauthorized => e
    unless e.message == 'Invalid or expired token.'
      logger.warn "#{e.class}: #{e.message} #{uid}"
      logger.info e.backtrace.join("\n")
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uid}"
    logger.info e.backtrace.join("\n")
  end
end
