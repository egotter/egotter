class CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    "#{request.user_id}-#{request.uid}"
  end

  # Notice: This interval is for the job. It is not for creating records.
  def unique_in
    TwitterUser::CREATE_RECORD_INTERVAL - 1.minute
  end

  def after_skip(request_id, options = {})
    SkippedCreateTwitterUserWorker.perform_async(request_id, options)
  end

  def expire_in
    1.minute
  end

  def after_expire(request_id, options = {})
    ExpiredCreateTwitterUserWorker.perform_async(request_id, options)
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

    notify(request.user, request.uid)

    # Saved values and relations At this point:
    #   friends_size, followers_size
    #   friendships(efs+s3), followerships(efs+s3)
    #   statuses, mentions, favorites

    assemble_request = AssembleTwitterUserRequest.create!(twitter_user: task.twitter_user)
    AssembleTwitterUserWorker.new.perform(assemble_request.id)

  rescue CreateTwitterUserRequest::Error => e
    # Do nothing
  rescue => e
    logger.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    logger.info "Caused by #{e.cause.inspect}" if e.cause
    logger.info e.backtrace.join("\n")
  end

  private

  # TODO Implement as separated worker
  def notify(searcher, searchee_uid)
    searchee = User.authorized.select(:id).find_by(uid: searchee_uid)
    if searchee && (!searcher || searcher.id != searchee.id)
      CreateSearchReportWorker.perform_async(searchee.id, searcher_uid: searcher&.uid)
    end
  end
end
