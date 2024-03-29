class PerformAfterCommitWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
  prepend WorkExpiry
  prepend WorkUniqueness
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(twitter_user_id, data, options = {})
    twitter_user_id
  end

  def unique_in
    1.minute
  end

  # TODO Don't expire this job
  def expire_in
    12.hours
  end

  def timeout_in
    1.minute
  end

  # options:
  def perform(twitter_user_id, data, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    if TwitterUser.where(uid: twitter_user.uid).where('created_at > ?', twitter_user.created_at).exists?
      Airbag.warn "Duplicate TwitterUser found worker=#{self.class} twitter_user_id=#{twitter_user_id} uid=#{twitter_user.uid}"
    end

    data = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data)))

    do_perform(
        twitter_user_id,
        data['uid'],
        data['screen_name'],
        data['profile'],
        data['friend_uids'],
        data['follower_uids'],
        data['status_tweets'],
        data['favorite_tweets'],
        data['mention_tweets']
    )
  end

  private

  def do_perform(id, uid, screen_name, profile, friend_uids, follower_uids, status_tweets, favorite_tweets, mention_tweets)
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

    TwitterUser.find(id).update(cache_created_at: Time.zone.now)
  rescue => e
    Airbag.exception e, twitter_user_id: id
  end
end
