class CreateTwitterUserWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
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
    2.minutes
  end

  def after_expire(request_id, options = {})
    ExpiredCreateTwitterUserWorker.perform_async(request_id, options)
  end

  def timeout_in
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
    context = options['context'] == :reporting ? :reporting : nil
    twitter_user = request.perform(context)

    notify(request.user, request.uid)

    assemble_request = AssembleTwitterUserRequest.create!(twitter_user: twitter_user, user_id: twitter_user.user_id, uid: twitter_user.uid)
    AssembleTwitterUserWorker.perform_in(5.seconds, assemble_request.id, requested_by: self.class)
    TwitterUserAssembledFlag.on(twitter_user.uid)
  rescue CreateTwitterUserRequest::TimeoutError => e
    if options['retries']
      Airbag.exception e, request_id: request_id, options: options
    else
      options['retries'] = 1
      CreateTwitterUserWorker.perform_in(rand(20) + unique_in, request_id, options)
    end
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
