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

  def perform(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    user = request.user
    return if user&.unauthorized?

    log = CreateTwitterUserLog.create(
        user_id: user&.id,
        request_id: request_id,
        uid: request.uid,
    )

    twitter_user = request.perform!
    request.finished!

    notify(user, request.uid) if user
    enqueue_next_jobs(request.user_id, request.uid, twitter_user)

    log.update(status: true)

      # Saved relations At this point:
    # friends_size, followers_size, statuses, mentions, favorites, friendships, followerships

  rescue Twitter::Error::TooManyRequests => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))

    if user
      TooManyRequestsQueue.new.add(user.id)
      ResetTooManyRequestsWorker.perform_in(e.rate_limit.reset_in.to_i, user.id)
    end
  rescue CreateTwitterUserRequest::Error => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))
  rescue => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def enqueue_next_jobs(user_id, uid, twitter_user)
    ImportTwitterUserRelationsWorker.perform_async(user_id, uid, twitter_user_id: twitter_user.id, enqueued_at: Time.zone.now)
    UpdateUsageStatWorker.perform_async(uid, user_id: user_id, enqueued_at: Time.zone.now)
    CreateScoreWorker.perform_async(uid)
    UpdateAudienceInsightWorker.perform_async(uid, enqueued_at: Time.zone.now, location: self.class, twitter_user_id: twitter_user.id)

    # WriteProfilesToS3Worker.perform_async([twitter_user.uid], user_id: user_id)
    # WriteProfilesToS3Worker.perform_async(twitter_user.instance_variable_get(:@friend_uids), user_id: user_id)
    # WriteProfilesToS3Worker.perform_async(twitter_user.instance_variable_get(:@follower_uids), user_id: user_id)

    DetectFailureWorker.perform_in(60.seconds, twitter_user.id, user_id: user_id, enqueued_at: Time.zone.now)
  end

  private

  def notify(login_user, searched_uid)
    searched_user = User.authorized.select(:id).find_by(uid: searched_uid)
    if searched_user && (!login_user || login_user.id != searched_user.id)
      CreateSearchReportWorker.perform_async(searched_user.id)
    end
  end
end
