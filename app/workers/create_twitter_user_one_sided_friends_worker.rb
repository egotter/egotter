class CreateTwitterUserOneSidedFriendsWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
  prepend WorkExpiry
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

  def timeout_in
    30.seconds
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    one_sided_friend_uids = twitter_user.calc_and_import(S3::OneSidedFriendship)
    one_sided_follower_uids = twitter_user.calc_and_import(S3::OneSidedFollowership)
    mutual_friend_uids = twitter_user.calc_and_import(S3::MutualFriendship)

    OneSidedFriendsCountPoint.create(uid: twitter_user.uid, value: one_sided_friend_uids.size)
    OneSidedFollowersCountPoint.create(uid: twitter_user.uid, value: one_sided_follower_uids.size)
    MutualFriendsCountPoint.create(uid: twitter_user.uid, value: mutual_friend_uids.size)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end
end
