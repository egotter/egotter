class StartSendingPromptReportsWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key
    -1
  end

  def unique_in
    1.minute
  end

  def timeout_in
    10.minutes
  end

  # options:
  #   last_queueing_started_at
  def perform(options = {})
    if options['last_queueing_started_at']
      time_diff = Time.zone.now - Time.zone.parse(options['last_queueing_started_at'])
      if time_diff < CreatePromptReportRequest::PROCESS_REQUEST_INTERVAL
        logger.info "Queueing interval of PromptReport is too short. It's started at #{options['last_queueing_started_at']}"
        StartSendingPromptReportsWorker.perform_in(CreatePromptReportRequest::PROCESS_REQUEST_INTERVAL - time_diff, options)
        return
      end
    end

    task = StartSendingPromptReportsTask.new

    log = StartSendingPromptReportsLog.create(started_at: Time.zone.now)
    log.update(properties: task.ids_stats)

    requests = create_requests(task.users)
    enqueue_requests(requests, log.started_at)

    log.update(finished_at: Time.zone.now)

  rescue => e
    notify_airbrake(e, options: options)
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end

  def create_requests(users)
    users.map { |user| CreatePromptReportRequest.new(user_id: user.id) }.tap do |requests|
      CreatePromptReportRequest.import requests, validate: false
    end
  end

  def enqueue_requests(requests, started_at)
    requests.each.with_index do |request, i|
      options = {user_id: request.user_id, index: i}

      if requests.last.id == request.id
        options[:start_next_loop] = true
        options[:queueing_started_at] = started_at
      end

      CreatePromptReportWorker.perform_async(request.id, options)
    end
  end
end
