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
  end

  desc 'Print errors'
  task print_errors: :environment do
    sigint = Util::Sigint.new.trap

    logger = TaskLogger.logger('log/batch.log')
    Rails.logger = logger

    user = ENV['USER_ID'] ? User.find(ENV['USER_ID']) : User.find_by(screen_name: ENV['SCREEN_NAME'])
    setting = user.notification_setting

    requests = CreatePromptReportRequest.where(user_id: user.id).order(created_at: :desc).limit(10).reverse
    logs = CreatePromptReportLog.where(user_id: user.id).order(created_at: :desc).limit(10).reverse
    reports = PromptReport.where(user_id: user.id).order(created_at: :desc).limit(10).reverse

    logger.info 'User'
    logger.info user.attributes.symbolize_keys.slice(:id, :uid, :screen_name, :authorized).inspect
    logger.info ''
    logger.info 'Setting'
    logger.info setting.attributes.symbolize_keys.slice(:dm, :report_interval, :permission_level).inspect
    logger.info ''
    logger.info 'Requests'
    requests.each { |req| logger.info req.attributes.symbolize_keys.inspect }
    logger.info ''
    logger.info 'Logs'
    logs.each { |log| logger.info log.attributes.symbolize_keys.inspect }
    logger.info ''
    logger.info 'PromptReports'
    reports.each { |report| logger.info report.attributes.symbolize_keys.inspect }
  end
end
