class StartSendingPromptReportsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  # options:
  #   last_queueing_started_at
  def perform(options = {})
    if options['last_queueing_started_at']
      time_diff = Time.zone.now - Time.zone.parse(options['last_queueing_started_at'])
      if time_diff < CreatePromptReportRequest::INTERVAL
        logger.warn "Interval is too short #{options['last_queueing_started_at']}"
        StartSendingPromptReportsWorker.perform_in(CreatePromptReportRequest::INTERVAL - time_diff, options)
        return
      end
    end

    task = PromptReportTask.start(user_ids_str: nil, deadline_str: nil)
    start_time = Time.zone.now
    users_size = task.users.size
    logger.warn "Start queueing #{users_size} users #{Time.zone.now}"

    task.users.each.with_index do |user, i|
      request = CreatePromptReportRequest.create(user_id: user.id)
      options = {user_id: user.id, index: i}

      if users_size - 1 == i
        options[:start_next_loop] = true
        options[:queueing_started_at] = start_time
      end

      CreatePromptReportWorker.perform_async(request.id, options)
    end

    logger.warn "Finish queueing #{users_size} users #{Time.zone.now}"

  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
