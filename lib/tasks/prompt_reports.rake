namespace :prompt_reports do
  desc 'Send PromptReport'
  task send: :environment do
    sigint = Util::Sigint.new.trap

    logger = TaskLogger.logger('log/batch.log')
    Rails.logger = logger

    user = ENV['USER_ID'] ? User.find(ENV['USER_ID']) : User.find_by(screen_name: ENV['SCREEN_NAME'])
    force = ENV['FORCE'] == 'true'

    request = CreatePromptReportRequest.create(user_id: user.id)
    if force
      ForceCreatePromptReportWorker.perform_async(request.id)
    else
      CreatePromptReportWorker.perform_async(request.id)
    end

    sleep 10

    puts <<~TEXT
      Requests
      #{request.inspect}

      Log
      #{CreatePromptReportLog.find_by(request_id: request.id).inspect}

      Message
      #{PromptReport.order(created_at: :desc).find_by(user_id: user.id).inspect}
    TEXT
  end

  desc 'Print errors'
  task print_errors: :environment do
    sigint = Util::Sigint.new.trap

    logger = TaskLogger.logger('log/batch.log')
    Rails.logger = logger

    user = ENV['USER_ID'] ? User.find(ENV['USER_ID']) : User.find_by(screen_name: ENV['SCREEN_NAME'])
    limit = ENV['LIMIT'] || 10
    setting = user.notification_setting

    error = CreatePromptReportValidator.new(user: user).validate! rescue $!
    days = user.access_days.order(created_at: :desc).limit(limit)
    requests = CreatePromptReportRequest.where(user_id: user.id).order(created_at: :desc).limit(limit)
    logs = CreatePromptReportLog.where(user_id: user.id).order(created_at: :desc).limit(limit)
    reports = PromptReport.where(user_id: user.id).order(created_at: :desc).limit(limit)

    blocked_user = BlockedUser.find_by(screen_name: user.screen_name)

    puts <<~TEXT
      validate!
      #{error.inspect}

      Days
      #{days.map(&:date).inspect}

      User
      #{user.attributes.symbolize_keys.slice(:id, :uid, :screen_name, :authorized).inspect}

      Blocked
      #{blocked_user.inspect}

      Setting
      #{setting.attributes.symbolize_keys.slice(:dm, :report_interval, :permission_level).inspect}

      Requests desc
      #{requests.map { |req| req.attributes.symbolize_keys.inspect }.join("\n")}

      Logs desc
      #{logs.map { |log| log.attributes.symbolize_keys.inspect }.join("\n")}

      PromptReports desc
      #{reports.map { |report| report.attributes.symbolize_keys.inspect }.join("\n")}
    TEXT
  end
end
