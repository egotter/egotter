class CreateTwitterUserInactiveFriendsWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
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

  def after_timeout(*args)
    Airbag.warn 'Job timed out', job_details(*args)
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

    inactive_friend_uids = import_uids(S3::InactiveFriendship, twitter_user)
    inactive_follower_uids = import_uids(S3::InactiveFollowership, twitter_user)
    import_uids(S3::InactiveMutualFriendship, twitter_user)

    CreateInactiveFriendsCountPointWorker.perform_async(twitter_user.uid, inactive_friend_uids.size)
    CreateInactiveFollowersCountPointWorker.perform_async(twitter_user.uid, inactive_follower_uids.size)

    DeleteInactiveFriendshipsWorker.perform_async(twitter_user.uid)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end

  private

  def import_uids(klass, twitter_user)
    uids = twitter_user.calc_uids_for(klass)
    klass.import_from!(twitter_user.uid, uids)
    twitter_user.update_counter_cache_for(klass, uids.size)
    uids
  end
end
