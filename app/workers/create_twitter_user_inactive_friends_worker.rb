class CreateTwitterUserInactiveFriendsWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def unique_in
    10.minutes
  end

  def after_skip(*args)
    Airbag.warn 'Job skipped', job_details(*args)
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    Airbag.warn 'Job expired', job_details(*args)
  end

  def timeout_in
    30.seconds
  end

  def job_details(twitter_user_id, options = {})
    user = TwitterUser.find(twitter_user_id)
    {class: self.class, twitter_user_id: twitter_user_id, friends_count: user.friends_count, followers_count: user.followers_count}
  rescue
    {class: self.class, twitter_user_id: twitter_user_id}
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    inactive_friend_uids = twitter_user.calc_and_import(S3::InactiveFriendship)
    inactive_follower_uids = twitter_user.calc_and_import(S3::InactiveFollowership)
    twitter_user.calc_and_import(S3::InactiveMutualFriendship)

    InactiveFriendsCountPoint.create(uid: twitter_user.uid, value: inactive_friend_uids.size)
    InactiveFollowersCountPoint.create(uid: twitter_user.uid, value: inactive_follower_uids.size)

    DeleteInactiveFriendshipsWorker.perform_async(twitter_user.uid)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end
end
