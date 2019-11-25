class CreatePromptReportInitializationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def after_skip(user_id, options = {})
    log(Hashie::Mash.new(options)).update(status: false, error_class: DuplicateJobSkipped, error_message: "Direct message not sent #{user_id} #{options.inspect}")
  end

  class Unauthorized < StandardError
  end

  class DuplicateJobSkipped < StandardError
  end

  # options:
  #   create_prompt_report_request_id
  def perform(user_id, options = {})
    user = User.find(user_id)
    unless user.authorized?
      log(options).update(status: false, error_class: Unauthorized, error_message: "Direct message not sent #{user_id} #{options.inspect}")
      return
    end

    PromptReport.initialization(user.id).deliver!

    log(options).update(status: false, error_class: CreatePromptReportRequest::InitializationStarted)

  rescue => e
    if TemporaryDmLimitation.temporarily_locked?(e)
    elsif TemporaryDmLimitation.you_have_blocked?(e)
      CreateBlockedUserWorker.perform_async(user.uid, user.screen_name)
    elsif TemporaryDmLimitation.not_allowed_to_access_or_delete_dm?(e)
    else
      logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"
      logger.warn e.cause.inspect if e.cause
      logger.info e.backtrace.join("\n")
    end

    log(options).update(status: false, error_class: e.class, error_message: e.message)
  end

  private

  def log(options)
    CreatePromptReportLog.find_or_initialize_by(request_id: options['create_prompt_report_request_id'])
  end
end
