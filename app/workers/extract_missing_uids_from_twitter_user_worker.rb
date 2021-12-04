class ExtractMissingUidsFromTwitterUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    create_missing_twitter_db_users(twitter_user)
  rescue => e
    handle_worker_error(e, twitter_user_id: twitter_user_id, **options)
  end

  private

  def create_missing_twitter_db_users(twitter_user)
    if (missing_friend_uids = fetch_missing_uids(twitter_user.friend_uids)).any?
      logger.info "#{self.class}: missing friend uids found twitter_user_id=#{twitter_user.id} size=#{missing_friend_uids.size} uids=#{missing_friend_uids.take(10).inspect}"
    end

    if (missing_follower_uids = fetch_missing_uids(twitter_user.follower_uids)).any?
      logger.info "#{self.class}: missing follower uids found twitter_user_id=#{twitter_user.id} size=#{missing_follower_uids.size} uids=#{missing_follower_uids.take(10).inspect}"
    end

    update_twitter_db_users((missing_friend_uids + missing_follower_uids).uniq, twitter_user.user_id)
  end

  def fetch_missing_uids(uids)
    uids = uids.uniq
    missing_uids = []

    uids.each_slice(1000) do |uids_array|
      if uids_array.size != TwitterDB::User.where(uid: uids_array).size
        missing_uids << uids_array - TwitterDB::User.where(uid: uids_array).pluck(:uid)
      end
    end

    missing_uids.flatten
  end

  def update_twitter_db_users(uids, user_id)
    if uids.any? && !TwitterDBUsersUpdatedFlag.on?(uids)
      TwitterDBUsersUpdatedFlag.on(uids)
      CreateTwitterDBUserWorker.compress_and_perform_async(uids, user_id: user_id, enqueued_by: "#{self.class} size=#{uids.size}")
    end
  end
end
