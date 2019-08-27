class StartSendingPromptReportsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    task = PromptReportTask.start(user_ids_str: nil, deadline_str: nil)
    start_time = Time.zone.now
    users_size = task.users.size
    Rails.logger.warn "Start queueing #{users_size}users #{Time.zone.now}"

    task.users.each.with_index do |user, i|
      request = CreatePromptReportRequest.create(user_id: user.id)

      options = {user_id: user.id, index: i}

      if users_size - 1 == i
        options[:start_next_loop] = true
        options[:queueing_started_at] = start_time
      end

      CreatePromptReportWorker.perform_async(request.id, options)
    end

    Rails.logger.warn "Finish queueing #{users_size}users #{Time.zone.now}"

  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
