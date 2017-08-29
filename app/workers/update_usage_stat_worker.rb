class UpdateUsageStatWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uid, options = {})
    stat = UsageStat.find_by(uid: uid)
    return if stat&.fresh?

    twitter_user = TwitterUser.select(:uid).latest(uid)
    statuses =
      if twitter_user.statuses.exists?
        twitter_user.statuses
      else
        user = User.find_by(id: options['user_id'])
        user = User.authorized.find_by(uid: uid) unless user
        client = user ? user.api_client : Bot.api_client
        client.user_timeline(uid.to_i).map { |s| Status.new(Status.slice_status_info(s)) }
      end

    if statuses.any?
      UsageStat.builder(uid).statuses(statuses).build.save!
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uid}"
  end
end
