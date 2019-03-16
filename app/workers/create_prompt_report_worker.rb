class CreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def request_class
    CreatePromptReportRequest
  end

  def log_class
    CreatePromptReportLog
  end

  def perform(request_id, options = {})
    options = options.with_indifferent_access
    request = request_class.find(request_id)
    user = request.user

    log = log_class.create(
        user_id: user.id,
        request_id: request_id,
        uid: user.uid,
        screen_name: user.screen_name
    )

    dm = request.perform!
    request.finished!

    PromptReport.find_by(message_id: dm.id).update(message_cache: truncated_message(dm))
    log.update(status: true)

  rescue request_class::Error => e
    log.update(error_class: e.class, error_message: e.message)
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
  rescue => e
    log.update(error_class: e.class, error_message: e.message)
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  ensure
    if options['start_next_loop']
      if options['queueing_started_at']
        start_time = Time.zone.parse(options['queueing_started_at'])
        StartSendingPromptReportsWorker.perform_at(start_time + request_class::INTERVAL)
      else
        StartSendingPromptReportsWorker.perform_in(request_class::INTERVAL.since)
      end
    end
  end

  def truncated_message(dm, truncate_at: 100)
    dm.text.remove(/\R/).gsub(%r{https?://[\S]+}, 'URL').truncate(truncate_at)
  end
end
