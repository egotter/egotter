class CreateTwitterUserCloseFriendsWorker
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
    user = User.find_by(id: twitter_user.user_id)

    if (close_friend_uids = twitter_user.calc_uids_for(S3::CloseFriendship, login_user: user))
      S3::CloseFriendship.import_from!(twitter_user.uid, close_friend_uids)
    end

    if (favorite_friend_uids = twitter_user.calc_uids_for(S3::FavoriteFriendship, login_user: user))
      S3::FavoriteFriendship.import_from!(twitter_user.uid, favorite_friend_uids)
    end

    update_twitter_db_users((close_friend_uids + favorite_friend_uids).uniq, twitter_user.user_id, self.class)

    CloseFriendship.delete_by_uid(twitter_user.uid)
    FavoriteFriendship.delete_by_uid(twitter_user.uid)
  rescue => e
    Airbag.warn "#{e.inspect.truncate(100)} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end

  private

  def update_twitter_db_users(uids, user_id, enqueued_by)
    if uids.any? && !TwitterDBUsersUpdatedFlag.on?(uids)
      TwitterDBUsersUpdatedFlag.on(uids)
      CreateTwitterDBUserWorker.perform_async(uids, user_id: user_id, enqueued_by: enqueued_by)
    end
  end
end
