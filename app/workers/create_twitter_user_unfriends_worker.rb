class CreateTwitterUserUnfriendsWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
  prepend WorkExpiry
  prepend WorkUniqueness
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
    60.seconds
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    if TwitterUser.where(uid: twitter_user.uid).where('created_at > ?', twitter_user.created_at).exists?
      Airbag.warn "Duplicate TwitterUser found worker=#{self.class} twitter_user_id=#{twitter_user_id} uid=#{twitter_user.uid}"
    end

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
