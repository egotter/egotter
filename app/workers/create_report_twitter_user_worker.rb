# I want to print this class name to sidekiq.log.
class CreateReportTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def after_skip(request_id, options = {})
    SkippedReportTwitterUserWorker.perform_async(request_id, options)
  end

  def expire_in
    2.hours
  end

  def after_expire(request_id, options = {})
    ExpiredReportTwitterUserWorker.perform_async(request_id, options)
  end

  def perform(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    PeriodicReportReportableFlag.create(user_id: request.user_id)

    task = CreateTwitterUserTask.new(request)
    task.start!(:reporting)
  rescue CreateTwitterUserRequest::Unknown => e
    # Suppress redundant message: CreateTwitterUserRequest::Unknown -> ApiClient::RetryExhausted -> HTTP::TimeoutError: execution expired
    logger.warn "#{e.inspect.truncate(200)} request_id=#{request_id} options=#{options}"
  rescue CreateTwitterUserRequest::Error => e
    # Do nothing
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end
