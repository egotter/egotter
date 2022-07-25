# I want to print this class name to sidekiq.log.
class CreateReportTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_in
    10.seconds
  end

  def after_skip(request_id, options = {})
    SkippedReportTwitterUserWorker.perform_async(request_id, options)
  end

  def expire_in
    2.hours
  end

  def after_expire(request_id, options = {})
    ExpiredReportTwitterUserWorker.perform_async(request_id, options)
  end

  # options:
  #   period
  def perform(request_id, options = {})
    request = CreateTwitterUserRequest.find(request_id)
    PeriodicReportReportableFlag.create(user_id: request.user_id)
    PeriodicReportReportableFlag.on(request.user_id, options['period'])
    request.perform(:reporting)
  rescue CreateTwitterUserRequest::TimeoutError => e
    if options['retries']
      Airbag.exception e, request_id: request_id, options: options
    else
      options['retries'] = 1
      CreateReportTwitterUserWorker.perform_in(rand(20) + unique_in, request_id, options)
    end
  rescue CreateTwitterUserRequest::Error => e
    # Do nothing
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end
