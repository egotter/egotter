class CreateTwitterUserUnfriendsWorker
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
    60.seconds
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

    unfriend_uids = twitter_user.calc_and_import(S3::Unfriendship)
    unfollower_uids = twitter_user.calc_and_import(S3::Unfollowership)
    mutual_unfriend_uids = twitter_user.calc_and_import(S3::MutualUnfriendship)

    # TODO Temporarily stopped
    # CreateTwitterDBUsersForMissingUidsWorker.push_bulk(unfriend_uids + unfollower_uids + mutual_unfriend_uids, twitter_user.user_id, enqueued_by: self.class)

    UnfriendsCountPoint.create(uid: twitter_user.uid, value: unfriend_uids.size)
    UnfollowersCountPoint.create(uid: twitter_user.uid, value: unfollower_uids.size)

    NewUnfriendsCountPoint.create(uid: twitter_user.uid, value: twitter_user.calc_new_unfriend_uids.size)
    NewUnfollowersCountPoint.create(uid: twitter_user.uid, value: twitter_user.calc_new_unfollower_uids.size)

    DeleteUnfriendshipsWorker.perform_async(twitter_user.uid)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end
end
