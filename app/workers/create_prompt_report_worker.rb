class CreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    10.minutes
  end

  # Because it is difficult to adjust the degree of parallelism,
  # this job is executed by a background-worker instead of cron.
  # options:
  #   user_id
  #   index
  #   start_next_loop
  #   queueing_started_at
  def perform(request_id, options = {})
    options = options.with_indifferent_access
    request = CreatePromptReportRequest.find(request_id)
    user = request.user

    log = CreatePromptReportLog.create(
        user_id: user.id,
        request_id: request_id,
        uid: user.uid,
        screen_name: user.screen_name
    )

    ApplicationRecord.benchmark("CreatePromptReportRequest#perform! Perform request #{request_id}", level: :info) do
      request.perform!
    end
    request.finished!

    log.update(status: true)

  rescue CreatePromptReportRequest::Error => e
    log.update(error_class: e.class, error_message: e.message)
  rescue => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  ensure
    if options['start_next_loop']
      time_diff = Time.zone.now - Time.zone.parse(options['queueing_started_at'])
      time_diff /= 3600
      logger.warn "Prompt reports time elapsed #{sprintf('%.3f hours', time_diff)}"
      StartSendingPromptReportsWorker.perform_async(last_queueing_started_at: options['queueing_started_at'])
    end
  end
end
