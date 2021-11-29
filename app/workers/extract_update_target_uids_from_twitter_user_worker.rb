# TODO Update -> Create
class ExtractUpdateTargetUidsFromTwitterUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    if (missing_friend_uids = fetch_missing_uids(twitter_user.friend_uids)).any?
      logger.info "#{self.class}: missing friend uids found twitter_user_id=#{twitter_user_id} size=#{missing_friend_uids.size} uids=#{missing_friend_uids.take(10).inspect}"
    end

    if (missing_follower_uids = fetch_missing_uids(twitter_user.follower_uids)).any?
      logger.info "#{self.class}: missing follower uids found twitter_user_id=#{twitter_user_id} size=#{missing_follower_uids.size} uids=#{missing_follower_uids.take(10).inspect}"
    end

    target_uids = (missing_friend_uids + missing_follower_uids).uniq
    if target_uids.any?
      CreateTwitterDBUserWorker.compress_and_perform_async(target_uids, user_id: twitter_user.user_id, enqueued_by: self.class)
    end
  rescue => e
    handle_worker_error(e, twitter_user_id: twitter_user_id, **options)
  end

  private

  def fetch_missing_uids(uids)
    persisted_uids = []
    uids.each_slice(1000) do |uids_array|
      persisted_uids << TwitterDB::User.where(uid: uids_array).pluck(:uid)
    end
    uids - persisted_uids.flatten
  end
end
