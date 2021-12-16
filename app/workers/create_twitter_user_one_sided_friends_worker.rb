class CreateTwitterUserOneSidedFriendsWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def unique_in
    10.minutes
  end

  def after_skip(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    Airbag.warn "The job of #{self.class} is skipped twitter_user_id=#{twitter_user_id} created_at=#{twitter_user.created_at}"
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    Airbag.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in
    30.seconds
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    one_sided_friend_uids = import_uids(S3::OneSidedFriendship, twitter_user)
    one_sided_follower_uids = import_uids(S3::OneSidedFollowership, twitter_user)
    import_uids(S3::MutualFriendship, twitter_user)

    # CreateOneSidedFriendsCountPointWorker.perform_async(twitter_user.uid, one_sided_friend_uids.size)
    # CreateOneSidedFollowersCountPointWorker.perform_async(twitter_user.uid, one_sided_follower_uids.size)

    OneSidedFriendship.delete_by_uid(twitter_user.uid)
    OneSidedFollowership.delete_by_uid(twitter_user.uid)
    MutualFriendship.delete_by_uid(twitter_user.uid)
  rescue => e
    Airbag.warn "#{e.inspect.truncate(100)} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end

  private

  def import_uids(klass, twitter_user)
    uids = twitter_user.calc_uids_for(klass)
    klass.import_from!(twitter_user.uid, uids)
    twitter_user.update_counter_cache_for(klass, uids.size)
    uids
  end
end
