class StartSendingPromptReportsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

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
    start_time = Time.zone.now
    users_size = task.users.size
    logger.warn "Start queueing #{task.ids_stats.inspect}"

    task.users.each.with_index do |user, i|
      request = CreatePromptReportRequest.create(user_id: user.id)
      options = {user_id: user.id, index: i}

      if users_size - 1 == i
        options[:start_next_loop] = true
        options[:queueing_started_at] = start_time
      end

      CreatePromptReportWorker.perform_async(request.id, options)
    end

    logger.warn "Finish queueing #{users_size} users"

  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
