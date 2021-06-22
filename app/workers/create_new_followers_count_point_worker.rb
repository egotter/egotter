class CreateNewFollowersCountPointWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'excluded_jobs', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def unique_in
    1.minute
  end

  # options:
  #   force
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)

    if options['force'] || NewFollowersCountPoint.where(uid: twitter_user.uid).exists?
      NewFollowersCountPoint.create_by_twitter_user(twitter_user)
    else
      NewFollowersCountPoint.import_by_uid(twitter_user.uid, async: true)
    end
  rescue => e
    handle_worker_error(e, twitter_user_id: twitter_user_id, **options)
  end
end
