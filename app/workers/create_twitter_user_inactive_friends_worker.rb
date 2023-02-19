class CreateTwitterUserInactiveFriendsWorker
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
    if TwitterUser.where(uid: twitter_user.uid).where('created_at > ?', twitter_user.created_at).exists?
      Airbag.warn "Duplicate TwitterUser found worker=#{self.class} twitter_user_id=#{twitter_user_id} uid=#{twitter_user.uid}"
    end

    inactive_friend_uids = twitter_user.calc_and_import(S3::InactiveFriendship)
    inactive_follower_uids = twitter_user.calc_and_import(S3::InactiveFollowership)
    twitter_user.calc_and_import(S3::InactiveMutualFriendship)

    InactiveFriendsCountPoint.create(uid: twitter_user.uid, value: inactive_friend_uids.size)
    InactiveFollowersCountPoint.create(uid: twitter_user.uid, value: inactive_follower_uids.size)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end
end
