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
    logger.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in
    3.minutes
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    if (uids = twitter_user.calc_new_friend_uids)
      twitter_user.update(new_friends_size: uids.size)
      CreateNewFriendsCountPointWorker.perform_async(twitter_user_id)
    end
  rescue => e
    logger.warn "#{e.inspect.truncate(100)} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
