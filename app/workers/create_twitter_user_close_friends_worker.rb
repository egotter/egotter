class CreateTwitterUserCloseFriendsWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    TwitterUser.find(twitter_user_id).uid
  end

  def unique_in
    10.minutes
  end

  def after_skip(*args)
    logger.warn "The job of #{self.class} is skipped args=#{args.inspect}"
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    logger.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in
    30.seconds
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    user = User.find_by(id: twitter_user.user_id)

    import_close_friends(twitter_user, user)
    import_favorite_friends(twitter_user, user)

    CloseFriendship.delete_by_uid(twitter_user.uid)
    FavoriteFriendship.delete_by_uid(twitter_user.uid)
  rescue => e
    logger.warn "#{e.inspect.truncate(100)} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  private

  def import_close_friends(twitter_user, user)
    uids = twitter_user.calc_uids_for(S3::CloseFriendship, login_user: user)
    S3::CloseFriendship.import_from!(twitter_user.uid, uids)
    CreateHighPriorityTwitterDBUserWorker.compress_and_perform_async(uids, user_id: twitter_user.user_id, enqueued_by: "#{self.class} > CloseFriends")
    CreateCloseFriendsOgImageWorker.perform_async(twitter_user.uid, uids: uids, force: true)
  end

  def import_favorite_friends(twitter_user, user)
    uids = twitter_user.calc_uids_for(S3::FavoriteFriendship, login_user: user)
    S3::FavoriteFriendship.import_from!(twitter_user.uid, uids)
    CreateHighPriorityTwitterDBUserWorker.compress_and_perform_async(uids, user_id: twitter_user.user_id, enqueued_by: "#{self.class} > FavoriteFriends")
  end
end
