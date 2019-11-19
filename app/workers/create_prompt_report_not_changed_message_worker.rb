class CreatePromptReportNotChangedMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  # options:
  #   changes_json
  #   previous_twitter_user_id
  #   current_twitter_user_id
  #   create_prompt_report_request_id
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    PromptReport.not_changed(
        user.id,
        changes_json: options['changes_json'],
        previous_twitter_user: TwitterUser.find(options['previous_twitter_user_id']),
        current_twitter_user: TwitterUser.find(options['current_twitter_user_id'])
    ).deliver

  rescue => e
    if TemporaryDmLimitation.temporarily_locked?(e)
      if TemporaryDmLimitation.you_have_blocked?(e)
        CreateBlockedUserWorker.perform_async(user.uid, user.screen_name)
      end
    elsif TemporaryDmLimitation.not_allowed_to_access_or_delete_dm?(e)
    else
      logger.warn "¥#{e.class} #{e.message} #{user_id} #{options.inspect}"
      logger.info e.backtrace.join("\n")
    end

    ex = CreatePromptReportRequest::DirectMessageNotSent.new("#{e.class}: #{e.message}")
    CreatePromptReportLog.find_by(request_id: options['create_prompt_report_request_id']).update(status: false, error_class: ex.class, error_message: ex.message)
  end
end
