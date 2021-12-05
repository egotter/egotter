# TODO Rename to CreateTwitterDBUsersForMissingUidsOfTwitterUser
class ExtractMissingUidsFromTwitterUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    uids = (twitter_user.friend_uids + twitter_user.follower_uids).uniq
    CreateTwitterDBUsersForMissingUidsWorker.perform_async(uids, twitter_user.user_id)
  rescue => e
    handle_worker_error(e, twitter_user_id: twitter_user_id, **options)
  end
end
