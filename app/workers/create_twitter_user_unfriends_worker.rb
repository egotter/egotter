class CreateTwitterUserUnfriendsWorker
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
    Airbag.warn "The job of #{self.class} is skipped", job_details(*args)
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    Airbag.warn "The job of #{self.class} is expired", job_details(*args)
  end

  def timeout_in
    60.seconds
  end

  def after_timeout(*args)
    Airbag.warn "The job of #{self.class} timed out", job_details(*args)
  end

  def job_details(twitter_user_id, options = {})
    user = TwitterUser.find(twitter_user_id)
    {twitter_user_id: twitter_user_id, friends_count: user.friends_count, followers_count: user.followers_count}
  rescue
    {twitter_user_id: twitter_user_id}
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    unfriend_uids = import_uids(S3::Unfriendship, twitter_user)
    unfollower_uids = import_uids(S3::Unfollowership, twitter_user)
    mutual_unfriend_uids = import_uids(S3::MutualUnfriendship, twitter_user)
    CreateTwitterDBUserWorker.perform_async((unfriend_uids + unfollower_uids + mutual_unfriend_uids).uniq, user_id: twitter_user.user_id, enqueued_by: self.class)

    CreateUnfriendsCountPointWorker.perform_async(twitter_user.uid, unfriend_uids.size)
    CreateUnfollowersCountPointWorker.perform_async(twitter_user.uid, unfollower_uids.size)

    CreateNewUnfriendsCountPointWorker.perform_async(twitter_user.uid, twitter_user.calc_new_unfriend_uids.size)
    CreateNewUnfollowersCountPointWorker.perform_async(twitter_user.uid, twitter_user.calc_new_unfollower_uids.size)

    DeleteUnfriendshipsWorker.perform_async(twitter_user.uid)
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
