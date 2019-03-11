class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(values = {})
    values = values.with_indifferent_access
    "#{values['user_id']}-#{values['uid']}"
  end

  def perform(values = {})
    track = Track.find(values['track_id'])

    job_attrs = values.slice('user_id', 'uid', 'screen_name', 'enqueued_at').
        merge(worker_class: self.class, jid: jid, started_at: Time.zone.now)
    job = track.jobs.create!(job_attrs)

    user = User.find_by(id: job.user_id)
    if user&.unauthorized?
      return job.update(error_class: 'Unauthorized')
    end

    user_id = job.user_id
    uid = job.uid

    request = CreateTwitterUserRequest.create(user_id: user_id, uid: uid)
    twitter_user = request.perform!
    request.finished!

    notify(user, uid) if user
    job.update(twitter_user_id: twitter_user.id, finished_at: Time.zone.now)

    enqueue_next_jobs(user_id, uid, twitter_user, track)

    # Saved relations At this point:
    # friends_size, followers_size, statuses, mentions, favorites, friendships, followerships

  rescue Twitter::Error::TooManyRequests => e
    job.update(error_class: e.class, error_message: e.message.truncate(100))

    TooManyRequestsQueue.new.add(user_id)
    ResetTooManyRequestsWorker.perform_in(e.rate_limit.reset_in.to_i, user_id)

  rescue CreateTwitterUserRequest::Error => e
    job.update(error_class: e.class, error_message: e.message.truncate(100))
    logger.info "#{e.class} #{e.message} #{values.inspect}"
  rescue => e
    job.update(error_class: e.class, error_message: e.message.truncate(100))
    logger.warn "#{e.class} #{e.message} #{values.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def enqueue_next_jobs(user_id, uid, twitter_user, track)
    ImportTwitterUserRelationsWorker.perform_async(user_id, uid, twitter_user_id: twitter_user.id, enqueued_at: Time.zone.now, track_id: track.id)
    UpdateUsageStatWorker.perform_async(uid, user_id: user_id, track_id: track.id, enqueued_at: Time.zone.now)
    CreateScoreWorker.perform_async(uid, track_id: track.id)
    UpdateAudienceInsightWorker.perform_async(uid, enqueued_at: Time.zone.now)

    # WriteProfilesToS3Worker.perform_async([twitter_user.uid], user_id: user_id)
    # WriteProfilesToS3Worker.perform_async(twitter_user.instance_variable_get(:@friend_uids), user_id: user_id)
    # WriteProfilesToS3Worker.perform_async(twitter_user.instance_variable_get(:@follower_uids), user_id: user_id)

    DetectFailureWorker.perform_in(60.seconds, twitter_user.id, user_id: user_id, track_id: track.id, enqueued_at: Time.zone.now)
  end

  private

  def notify(login_user, searched_uid)
    searched_user = User.authorized.select(:id).find_by(uid: searched_uid)
    if searched_user && (!login_user || login_user.id != searched_user.id)
      CreateSearchReportWorker.perform_async(searched_user.id)
    end
  end
end
