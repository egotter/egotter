class CreatePromptReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    10.minutes
  end

  # Because it is difficult to adjust the degree of parallelism,
  # this job is executed by a background-worker instead of cron.
  #
  # options:
  #   user_id
  #   index
  #   start_next_loop
  #   queueing_started_at
  def perform(request_id, options = {})
    request = CreatePromptReportRequest.find(request_id)
    CreatePromptReportTask.new(request).start!

  rescue CreatePromptReportRequest::Error => e
    notify_airbrake(e, request_id: request_id, options: options)
  rescue => e
    notify_airbrake(e, request_id: request_id, options: options)
  ensure
    if options['start_next_loop']
      time_diff = Time.zone.now - Time.zone.parse(options['queueing_started_at'])
      time_diff /= 3600
      StartSendingPromptReportsWorker.perform_async(last_queueing_started_at: options['queueing_started_at'])
    end
  end
end
