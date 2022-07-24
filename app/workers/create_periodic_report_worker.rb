class CreatePeriodicReportWorker
  include Sidekiq::Worker
  include ReportRetryHandler
  prepend WorkMeasurement
  sidekiq_options queue: 'report_low', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    CreatePeriodicReportRequest.find(request_id).user_id
  end

  UNIQUE_IN = 5.seconds

  def unique_in
    UNIQUE_IN
  end

  def after_skip(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)
    request.update(status: 'job_skipped')

    if user_requested_job?
      waiting_time = CreatePeriodicReportMessageWorker::UNIQUE_IN + 3.seconds
      CreatePeriodicReportRequestIntervalTooShortMessageWorker.perform_in(waiting_time, request.user_id)
    end

    Airbag.info "The job of #{self.class} is skipped request_id=#{request_id} options=#{options.inspect}"
  end

  def timeout_in
    60.seconds
  end

  def after_timeout(request_id, options = {})
    Airbag.warn "The job of #{self.class} timed out elapsed=#{sprintf("%.3f", elapsed_time)} request_id=#{request_id} options=#{options.inspect}"
    CreatePeriodicReportRequest.find(request_id).append_status('timeout').save
  end

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)
    return unless request.user.authorized?
    return if request.user.banned?

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

    CreatePeriodicReportTask.new(request).start!
  end

  def user_requested_job?
    self.class == CreateUserRequestedPeriodicReportWorker
  end

  def batch_requested_job?
    self.class == CreatePeriodicReportWorker
  end
end
