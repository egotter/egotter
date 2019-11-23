class CreatePromptReportInitializationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  # options:
  #   create_prompt_report_request_id
  def perform(user_id, options = {})
    user = User.find(user_id)
    unless user.authorized?
      log(options).update(status: false, error_class: CreatePromptReportRequest::Unauthorized, error_message: '')
      return
    end

    ex = nil
    message1 = I18n.t('dm.promptReportNotification.initialization_start', url: Rails.application.routes.url_helpers.settings_url(via: 'prompt_report_initialization', og_tag: 'false'))
    message2 = I18n.t('dm.promptReportNotification.search_yourself', screen_name: user.screen_name, url: timeline_url(user.screen_name))

    begin
      DirectMessageRequest.new(user.api_client.twitter, User::EGOTTER_UID, message1).perform
    rescue => e
      if TemporaryDmLimitation.temporarily_locked?(e)
      elsif TemporaryDmLimitation.you_have_blocked?(e)
        CreateBlockedUserWorker.perform_async(user.uid, user.screen_name)
      elsif TemporaryDmLimitation.not_allowed_to_access_or_delete_dm?(e)
      else
        logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"
        logger.info e.backtrace.join("\n")
      end

      ex = CreatePromptReportRequest::DirectMessageNotSent.new("Initialization message1 from user #{e.class}: #{e.message}")
      log(options).update(status: false, error_class: ex.class, error_message: ex.message)
    end

    return if ex

    begin
      DirectMessageRequest.new(User.egotter.api_client.twitter, user.uid, message2).perform
    rescue => e
      if TemporaryDmLimitation.temporarily_locked?(e)
      elsif TemporaryDmLimitation.you_have_blocked?(e)
        CreateBlockedUserWorker.perform_async(user.uid, user.screen_name)
      elsif TemporaryDmLimitation.not_allowed_to_access_or_delete_dm?(e)
      else
        logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"
        logger.info e.backtrace.join("\n")
      end

      ex = CreatePromptReportRequest::DirectMessageNotSent.new("Initialization message2 from egotter #{e.class}: #{e.message}")
      log(options).update(status: false, error_class: ex.class, error_message: ex.message)
    end

    return if ex

    log(options).update(status: false, error_class: CreatePromptReportRequest::InitializationStarted)

  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  private

  def timeline_url(screen_name)
    Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, via: 'prompt_report_search_yourself', og_tag: 'false')
  end

  def log(options)
    CreatePromptReportLog.find_or_initialize_by(request_id: options['create_prompt_report_request_id'])
  end
end
