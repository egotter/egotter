class CreateTwitterUserWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  include WorkerErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    CreateTwitterUserRequest.find(request_id).uid
  end

  def unique_in
    1.minute
  end

  def after_skip(request_id, options = {})
    SkippedCreateTwitterUserWorker.perform_async(request_id, options)
  end

  def expire_in
    30.seconds
  end

  def after_expire(request_id, options = {})
    ExpiredCreateTwitterUserWorker.perform_async(request_id, options)
  end

  def _timeout_in
    3.minutes
  end

  def after_timeout(request_id, options = {})
    TimedOutCreateTwitterUserWorker.perform_async(request_id, options)
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
    context = options['context'] == :reporting ? :reporting : nil
    task.start!(context)

    notify(request.user, request.uid)

    assemble_request = AssembleTwitterUserRequest.create!(twitter_user: task.twitter_user, user_id: task.twitter_user.user_id, uid: task.twitter_user.uid)
    AssembleTwitterUserWorker.perform_in(request.delay_for_importing, assemble_request.id, requested_by: self.class)
    TwitterUserAssembledFlag.on(task.twitter_user.uid)
  rescue CreateTwitterUserRequest::Error => e
    # Do nothing
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
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
