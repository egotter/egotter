class CreatePeriodicReportWorker
  include Sidekiq::Worker
  include ReportRetryHandler
  prepend WorkMeasurement
  sidekiq_options queue: 'report_low', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  UNIQUE_IN = 5.seconds

  def unique_in
    UNIQUE_IN
  end

  def timeout_in
    60.seconds
  end

  def after_timeout(request_id, options = {})
    Airbag.warn 'Job timed out', request_id: request_id, options: options
  end

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)
    return unless request.user.authorized?
    return if request.user.banned?

    if user_requested_job? &&
        CreatePeriodicReportRequest.where(user_id: request.user_id).where.not(id: request.id).where(created_at: (request.created_at - 10.seconds)..request.created_at).exists?
      request.update(status: 'job_skipped')
      return
    end

    if PeriodicReport.send_report_limited?(request.user.uid)
      retry_current_report(request_id, options)
      return
    end

    do_perform(request, options)
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end

  private

  def do_perform(request, options)
    request.worker_context = self.class
    request.check_credentials = true
    request.check_web_access = !request.user.has_valid_subscription?

    if request.user.has_valid_subscription?
      request.check_interval = false
      request.check_following_status = false
      request.check_allotted_messages_count = false
    else
      request.check_interval = user_requested_job?
      request.check_following_status = !request.user.has_valid_subscription? && user_requested_job?
      request.check_allotted_messages_count = batch_requested_job?
    end

    request.perform
  end

  def user_requested_job?
    self.class == CreateUserRequestedPeriodicReportWorker
  end

  def batch_requested_job?
    self.class == CreatePeriodicReportWorker
  end
end
