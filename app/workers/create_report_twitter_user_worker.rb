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
    PeriodicReportReportableFlag.on(request.user_id, options['period'])
    request.perform(:reporting)
  rescue CreateTwitterUserRequest::HttpTimeout, CreateTwitterUserRequest::Error => e
    Airbag.info "#{e.class} is ignored", exception: e.inspect
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end
end
