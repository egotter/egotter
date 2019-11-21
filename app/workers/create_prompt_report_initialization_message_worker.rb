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
    return unless user.authorized?

    message1 = I18n.t('dm.promptReportNotification.initialization_start')
    message2 = I18n.t('dm.promptReportNotification.search_yourself', screen_name: user.screen_name, url: timeline_url(user.screen_name))

    DirectMessageRequest.new(user.api_client.twitter, User::EGOTTER_UID, message1).perform
    DirectMessageRequest.new(User.egotter.api_client.twitter, user.uid, message2).perform

    log(options).update(status: false, error_class: CreatePromptReportRequest::InitializationStarted)

  rescue => e
    if TemporaryDmLimitation.temporarily_locked?(e)
      if TemporaryDmLimitation.you_have_blocked?(e)
        CreateBlockedUserWorker.perform_async(user.uid, user.screen_name)
      end
    elsif TemporaryDmLimitation.not_allowed_to_access_or_delete_dm?(e)
    else
      logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"
      logger.info e.backtrace.join("\n")
    end

    ex = CreatePromptReportRequest::DirectMessageNotSent.new("#{e.class}: #{e.message}")
    log(options).update(status: false, error_class: ex.class, error_message: ex.message)
  end

  def timeline_url(screen_name)
    Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, via: 'prompt_report_search_yourself')
  end

  def log(options)
    CreatePromptReportLog.find_by(request_id: options['create_prompt_report_request_id'])
  end
end
