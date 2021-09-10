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

  def after_skip(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    logger.warn "The job of #{self.class} is skipped twitter_user_id=#{twitter_user_id} created_at=#{twitter_user.created_at}"
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    logger.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in
    60.seconds
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    import_uids(S3::Unfriendship, twitter_user)
    import_uids(S3::Unfollowership, twitter_user)
    import_uids(S3::MutualUnfriendship, twitter_user)

    Unfriendship.delete_by_uid(twitter_user.uid)
    Unfollowership.delete_by_uid(twitter_user.uid)
    BlockFriendship.delete_by_uid(twitter_user.uid)
  rescue => e
    logger.warn "#{e.inspect.truncate(100)} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  private

  def import_uids(klass, twitter_user)
    uids = twitter_user.calc_uids_for(klass)
    klass.import_from!(twitter_user.uid, uids)
    twitter_user.update_counter_cache_for(klass, uids.size)
  end
end
