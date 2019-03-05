namespace :prompt_reports do
  desc 'send'
  task send: :environment do
    sigint = Util::Sigint.new.trap

    logger = PromptReportTask.logger
    Rails.logger = logger

    task = PromptReportTask.start(user_ids_str: ENV['USER_IDS'], deadline_str: ENV['DEADLINE'])

    logger.info 'Started'
    logger.info task.to_s(:deadline) if task.deadline
    logger.info task.to_s(:ids_stats)

    task.users.find_each.with_index do |user, i|
      unless TwitterUser.exists?(uid: user.uid)
        # TwitterUser::Batch.fetch_and_create(user.uid) # TODO Create in background
        next
      end

      if CreatePromptReportRequest.where(user_id: user.id, created_at: 1.hour.ago..Time.zone.now).exists?
        next
      end

      begin
        request = CreatePromptReportRequest.create(user_id: user.id)
        CreatePromptReportWorker.new.perform(request.id, user_id: user.id, exception: true)
      rescue => e
        task.add_error(user.id, e)
      end

      task.processed_count += 1
      logger.info task.to_s(:progress) if i % 1000 == 0

      logger.warn "It's overdue." && break if task.overdue?
      logger.warn "Too many errors." && break if task.fatal?
      break if sigint.trapped?
    end

    logger.info task.to_s(:finishing)
    logger.info 'Finished'

    if task.errors.any?
      logger.info "Errors:"
      logger.info task.to_s(:errors)
    end
  end
end
