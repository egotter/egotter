class CreateTwitterUserNewFriendsWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def unique_in
    10.minutes
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    Airbag.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def timeout_in
    3.minutes
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    if (new_friend_uids = twitter_user.calc_new_friend_uids)
      twitter_user.update(new_friends_size: new_friend_uids.size)
      NewFriendsCountPoint.create(uid: twitter_user.uid, value: new_friend_uids.size)
    end

    if (new_follower_uids = twitter_user.calc_new_follower_uids)
      twitter_user.update(new_followers_size: new_follower_uids.size)
      NewFollowersCountPoint.create(uid: twitter_user.uid, value: new_follower_uids.size)
    end

    CreateTwitterDBUserWorker.push_bulk(new_friend_uids + new_follower_uids, user_id: twitter_user.user_id, enqueued_by: self.class)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end
end
