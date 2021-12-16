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
    Airbag.warn "The job of #{self.class} is skipped twitter_user_id=#{twitter_user_id} created_at=#{twitter_user.created_at}"
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    Airbag.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in
    60.seconds
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    unfriend_uids = import_uids(S3::Unfriendship, twitter_user)
    unfollower_uids = import_uids(S3::Unfollowership, twitter_user)
    mutual_unfriend_uids = import_uids(S3::MutualUnfriendship, twitter_user)
    update_twitter_db_users((unfriend_uids + unfollower_uids + mutual_unfriend_uids).uniq, twitter_user.user_id)

    # CreateUnfriendsCountPointWorker.perform_async(twitter_user.uid, unfriend_uids.size)
    # CreateUnfollowersCountPointWorker.perform_async(twitter_user.uid, unfollower_uids.size)

    DeleteUnfriendshipsWorker.perform_async(twitter_user.uid)
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

  def update_twitter_db_users(uids, user_id)
    if uids.any? && !TwitterDBUsersUpdatedFlag.on?(uids)
      TwitterDBUsersUpdatedFlag.on(uids)
      CreateTwitterDBUserWorker.compress_and_perform_async(uids, user_id: user_id, enqueued_by: self.class)
    end
  end
end
