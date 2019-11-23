class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def expire_in
    1.minute
  end

  def after_expire(*args)
    DelayedCreateTwitterUserWorker.perform_async(*args)
  end

  # options:
  #   enqueued_at
  def perform(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    task = CreateTwitterUserTask.new(request)
    task.start!
    twitter_user = task.twitter_user
    user = request.user

    notify(user, request.uid) if user
    enqueue_next_jobs(request.user_id, request.uid, twitter_user)

    # Saved values and relations At this point:
    #   friends_size, followers_size
    #   friendships(efs+s3), followerships(efs+s3)
    #   statuses, mentions, favorites

  rescue Twitter::Error::TooManyRequests => e
    if user
      TooManyRequestsQueue.new.add(user.id)
      ResetTooManyRequestsWorker.perform_in(e.rate_limit.reset_in.to_i, user.id)
    end
  rescue CreateTwitterUserRequest::Error => e
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def enqueue_next_jobs(user_id, uid, twitter_user)
    ImportTwitterUserRelationsWorker.perform_async(user_id, uid, twitter_user_id: twitter_user.id, enqueued_at: Time.zone.now)
    UpdateUsageStatWorker.perform_async(uid, user_id: user_id, enqueued_at: Time.zone.now)
    UpdateAudienceInsightWorker.perform_async(uid, enqueued_at: Time.zone.now, location: self.class, twitter_user_id: twitter_user.id)
  end

  private

  def notify(login_user, searched_uid)
    searched_user = User.authorized.select(:id).find_by(uid: searched_uid)
    if searched_user && (!login_user || login_user.id != searched_user.id)
      CreateSearchReportWorker.perform_async(searched_user.id)
    end
  end
end
