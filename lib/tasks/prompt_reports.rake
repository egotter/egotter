namespace :prompt_reports do
  desc 'send'
  task send: :environment do
    sigint = Util::Sigint.new.trap
    Rails.logger.level = Logger::WARN

    task = PromptReportTask.start(user_ids_str: ENV['USER_IDS'], deadline_str: ENV['DEADLINE'])

    puts Time.zone.now.to_s + ' ' + 'Started'
    puts Time.zone.now.to_s + ' ' + task.to_s(:deadline) if task.deadline
    puts Time.zone.now.to_s + ' ' + task.to_s(:ids_stats)

    task.users.find_each.with_index do |user, i|
      unless TwitterUser.exists?(uid: user.uid)
        # TwitterUser::Batch.fetch_and_create(user.uid) # TODO Create in background
        next
      end

      begin
        request = CreatePromptReportRequest.create(user_id: user.id)
        CreatePromptReportWorker.new.perform(request.id, user_id: user.id, exception: true)
      rescue => e
        task.add_error(user.id, e)
      end

      task.processed_count += 1
      puts (Time.zone.now.to_s + ' ' + task.to_s(:progress)) if i % 1000 == 0

      break if task.overdue? || sigint.trapped? || task.fatal?
    end

    puts Time.zone.now.to_s + ' ' + task.to_s(:finishing)
    puts Time.zone.now.to_s + ' ' + 'Finished'

    if task.errors.any?
      puts "Errors:"
      puts task.to_s(:errors)
    end
  end
end
