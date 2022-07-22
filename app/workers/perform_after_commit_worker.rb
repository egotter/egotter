class PerformAfterCommitWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(twitter_user_id, data, options = {})
    twitter_user_id
  end

  def unique_in
    1.minute
  end

  def after_skip(twitter_user_id, data, options = {})
    Airbag.warn "The job of #{self.class} is skipped twitter_user_id=#{twitter_user_id}"
  end

  # TODO Don't expire this job
  def expire_in
    1.hour
  end

  def after_expire(twitter_user_id, data, options = {})
    Airbag.warn "The job of #{self.class} is expired twitter_user_id=#{twitter_user_id}"
  end

  def _timeout_in
    1.minute
  end

  # options:
  def perform(twitter_user_id, data, options = {})
    data = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data)))

    id = twitter_user_id
    uid = data['uid']
    screen_name = data['screen_name']
    profile = data['profile']
    friend_uids = data['friend_uids']
    follower_uids = data['follower_uids']
    status_tweets = data['status_tweets']
    favorite_tweets = data['favorite_tweets']
    mention_tweets = data['mention_tweets']

    Efs::TwitterUser.import_from!(id, uid, screen_name, profile, friend_uids, follower_uids)

    # Efs::StatusTweet, Efs::FavoriteTweet and Efs::MentionTweet are not imported for performance reasons

    S3::Friendship.import_from!(id, uid, screen_name, friend_uids, async: true)
    S3::Followership.import_from!(id, uid, screen_name, follower_uids, async: true)
    S3::Profile.import_from!(id, uid, screen_name, profile, async: true)

    if status_tweets&.is_a?(Array)
      S3::StatusTweet.import_from!(uid, screen_name, status_tweets)
    end

    if favorite_tweets&.is_a?(Array)
      S3::FavoriteTweet.import_from!(uid, screen_name, favorite_tweets)
    end

    if mention_tweets&.is_a?(Array)
      S3::MentionTweet.import_from!(uid, screen_name, mention_tweets)
    end

    TwitterUser.find(twitter_user_id).update(cache_created_at: Time.zone.now)
  rescue => e
    Airbag.warn "#{e.inspect.truncate(100)} twitter_user_id=#{twitter_user_id}", backtrace: e.backtrace
  end
end
