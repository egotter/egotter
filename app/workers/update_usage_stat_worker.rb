class UpdateUsageStatWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def expire_in
    10.minutes
  end

  # options:
  #   user_id
  #   location
  def perform(uid, options = {})
    stat = UsageStat.find_by(uid: uid)
    return if stat&.fresh?

    twitter_user = TwitterUser.select(:uid, :screen_name, :created_at).latest_by(uid: uid)
    statuses = twitter_user&.status_tweets

    if statuses.blank?
      tweets = fetch_tweets(uid, options)
      statuses = tweets.map { |s| TwitterDB::Status.build_by(twitter_user: twitter_user, status: s) }
    end

    if statuses.any?
      UsageStat.builder(uid).statuses(statuses).build.save!
    end

  rescue => e
    if AccountStatus.invalid_or_expired_token?(e) ||
        AccountStatus.not_authorized?(e) ||
        AccountStatus.temporarily_locked?(e) ||
        AccountStatus.blocked?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end

  def fetch_tweets(uid, options)
    user = User.find_by(id: options['user_id'])
    user = User.authorized.find_by(uid: uid) unless user
    client = user ? user.api_client : Bot.api_client
    client.user_timeline(uid.to_i)
  end
end
