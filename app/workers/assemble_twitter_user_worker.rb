class AssembleTwitterUserWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    AssembleTwitterUserRequest.find(request_id).twitter_user.uid
  end

  def unique_in
    5.minutes
  end

  def after_skip(request_id, options = {})
    SkippedAssembleTwitterUserWorker.perform_async(request_id, options)
    AssembleTwitterUserRequest.find(request_id).append_status('skipped')
  end

  def expire_in
    30.seconds
  end

  def after_expire(request_id, options = {})
    ExpiredAssembleTwitterUserWorker.perform_async(request_id, options)
    AssembleTwitterUserRequest.find(request_id).append_status('expired')
  end

  def timeout_in
    3.minutes
  end

  def after_timeout(request_id, options = {})
    TimedOutAssembleTwitterUserWorker.perform_async(request_id, options)
  end

  # options:
  def perform(request_id, options = {})
    request = AssembleTwitterUserRequest.find(request_id)
    request.perform!
    request.finished!
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end
end
