class CreateTwitterUserCloseFriendsWorker
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
    user = User.find_by(id: twitter_user.user_id)

    if (close_friend_uids = twitter_user.calc_uids_for(S3::CloseFriendship, login_user: user))
      S3::CloseFriendship.import_from!(twitter_user.uid, close_friend_uids)
    end

    if (favorite_friend_uids = twitter_user.calc_uids_for(S3::FavoriteFriendship, login_user: user))
      S3::FavoriteFriendship.import_from!(twitter_user.uid, favorite_friend_uids)
    end

    CreateTwitterDBUsersForMissingUidsWorker.push_bulk(close_friend_uids + favorite_friend_uids, twitter_user.user_id, enqueued_by: self.class)

    CloseFriendship.delete_by_uid(twitter_user.uid)
    FavoriteFriendship.delete_by_uid(twitter_user.uid)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end
end
