class CreateTwitterUserNewFriendsWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
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

  def after_expire(*args)
    Airbag.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in
    3.minutes
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    if (new_friend_uids = twitter_user.calc_new_friend_uids)
      twitter_user.update(new_friends_size: new_friend_uids.size)
      CreateNewFriendsCountPointWorker.perform_async(twitter_user.uid, new_friend_uids.size)
    end

    if (new_follower_uids = twitter_user.calc_new_follower_uids)
      twitter_user.update(new_followers_size: new_follower_uids.size)
      CreateNewFollowersCountPointWorker.perform_async(twitter_user.uid, new_follower_uids.size)
    end

    update_twitter_db_users((new_friend_uids + new_follower_uids).uniq, twitter_user.user_id)
  rescue => e
    Airbag.warn "#{e.inspect.truncate(100)} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end

  private

  def update_twitter_db_users(uids, user_id)
    if uids.any? && !TwitterDBUsersUpdatedFlag.on?(uids)
      TwitterDBUsersUpdatedFlag.on(uids)
      CreateTwitterDBUserWorker.perform_async(uids, user_id: user_id, enqueued_by: self.class)
    end
  end
end
