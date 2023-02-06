class PerformAfterCommitWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
  prepend WorkExpiry
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

  def timeout_in
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

    begin
      WriteEfsTwitterUserWorker.perform_async(
          {twitter_user_id: id, uid: uid, screen_name: screen_name, profile: profile,
           friend_uids: friend_uids, follower_uids: follower_uids}, {twitter_user_id: id}
      )
    rescue Redis::CannotConnectError => e
      Airbag.warn 'Queueing WriteEfsTwitterUserWorker failed', exception: e.inspect
      Efs::TwitterUser.import_from!(id, uid, screen_name, profile, friend_uids, follower_uids)
    end

    # Efs::StatusTweet, Efs::FavoriteTweet and Efs::MentionTweet are not imported for performance reasons

    begin
      WriteS3FriendshipWorker.perform_async(
          {twitter_user_id: id, uid: uid, screen_name: screen_name, friend_uids: friend_uids},
          {twitter_user_id: id}
      )
    rescue Redis::CannotConnectError => e
      Airbag.warn 'Queueing WriteS3FriendshipWorker failed', exception: e.inspect
      S3::Friendship.import_from!(id, uid, screen_name, friend_uids, async: false)
    end

    begin
      WriteS3FollowershipWorker.perform_async(
          {twitter_user_id: id, uid: uid, screen_name: screen_name, follower_uids: follower_uids},
          {twitter_user_id: id}
      )
    rescue Redis::CannotConnectError => e
      Airbag.warn 'Queueing WriteS3FollowershipWorker failed', exception: e.inspect
      S3::Followership.import_from!(id, uid, screen_name, follower_uids, async: false)
    end

    begin
      WriteS3ProfileWorker.perform_async(
          {twitter_user_id: id, uid: uid, screen_name: screen_name, profile: profile},
          {twitter_user_id: id}
      )
    rescue Redis::CannotConnectError => e
      Airbag.warn 'Queueing WriteS3ProfileWorker failed', exception: e.inspect
      S3::Profile.import_from!(id, uid, screen_name, profile, async: false)
    end

    if status_tweets&.is_a?(Array)
      begin
        WriteS3StatusTweetWorker.perform_async(
            {uid: uid, screen_name: screen_name, status_tweets: status_tweets},
            {uid: uid}
        )
      rescue Redis::CannotConnectError => e
        Airbag.warn 'Queueing WriteS3StatusTweetWorker failed', exception: e.inspect
        S3::StatusTweet.import_from!(uid, screen_name, status_tweets, async: false)
      end
    end

    if favorite_tweets&.is_a?(Array)
      begin
        WriteS3FavoriteTweetWorker.perform_async(
            {uid: uid, screen_name: screen_name, favorite_tweets: favorite_tweets},
            {uid: uid}
        )
      rescue Redis::CannotConnectError => e
        Airbag.warn 'Queueing WriteS3FavoriteTweetWorker failed', exception: e.inspect
        S3::FavoriteTweet.import_from!(uid, screen_name, favorite_tweets, async: false)
      end
    end

    if mention_tweets&.is_a?(Array)
      begin
        WriteS3MentionTweetWorker.perform_async(
            {uid: uid, screen_name: screen_name, mention_tweets: mention_tweets},
            {uid: uid}
        )
      rescue Redis::CannotConnectError => e
        Airbag.warn 'Queueing WriteS3MentionTweetWorker failed', exception: e.inspect
        S3::MentionTweet.import_from!(uid, screen_name, mention_tweets, async: false)
      end
    end

    TwitterUser.find(twitter_user_id).update(cache_created_at: Time.zone.now)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id
  end
end
