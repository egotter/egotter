class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    "#{request.user_id}-#{request.uid}"
  end

  # Notice: This interval is for the job. It is not for creating records.
  def unique_in
    5.minutes
  end

  def expire_in
    1.minute
  end

  def after_expire(*args)
    DelayedCreateTwitterUserWorker.perform_async(*args)
  end

  # options:
  #   requested_by
  #   session_id
  #   user_id
  #   uid
  #   ahoy_visit_id
  def perform(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    task = CreateTwitterUserTask.new(request)
    task.start!
    twitter_user = task.twitter_user

    enqueue_next_jobs(request.user_id, request.uid, twitter_user)
    notify(request.user, request.uid)

    # Saved values and relations At this point:
    #   friends_size, followers_size
    #   friendships(efs+s3), followerships(efs+s3)
    #   statuses, mentions, favorites

  rescue CreateTwitterUserRequest::Error => e
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    logger.info "Caused by #{e.cause.inspect}" if e.cause
    logger.info e.backtrace.join("\n")
  end

  def enqueue_next_jobs(user_id, uid, twitter_user)
    ImportTwitterUserRelationsWorker.perform_async(user_id, uid, twitter_user_id: twitter_user.id)
    UpdateUsageStatWorker.perform_async(uid, user_id: user_id, location: self.class)
    UpdateAudienceInsightWorker.perform_async(uid, location: self.class, twitter_user_id: twitter_user.id)
  end

  private

  def notify(searcher, searchee_uid)
    searchee = User.authorized.select(:id).find_by(uid: searchee_uid)
    if searchee && (!searcher || searcher.id != searchee.id)
      CreateSearchReportWorker.perform_async(searchee.id, searcher_uid: searcher&.uid)
    end
  end
end
