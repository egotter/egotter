class CreateFollowersCountPointWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(uid, value, time, options = {})
    "#{uid}-#{value}-#{time}"
  end

  def unique_in
    1.minute
  end

  # options:
  def perform(uid, value, time, options = {})
    if !FollowersCountPoint.where(uid: uid).exists? && TwitterUser.where(uid: uid).exists?
      FollowersCountPoint.import_from_twitter_users(uid)
    else
      FollowersCountPoint.create(uid: uid, value: value, created_at: time)
    end
  rescue => e
    handle_worker_error(e, uid: uid, value: value, time: time, **options)
  end
end
