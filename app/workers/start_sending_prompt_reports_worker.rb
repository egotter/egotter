class StartSendingPromptReportsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def perform(*args)
    task = PromptReportTask.start(user_ids_str: nil, deadline_str: nil)

    task.users.each.with_index do |user, i|
      request = CreatePromptReportRequest.create(user_id: user.id)

      options = {user_id: user.id, index: i}
      options[:start_next_loop] = true if task.users.size - 1 == i
      CreatePromptReportWorker.perform_async(request.id, options)
    end
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
