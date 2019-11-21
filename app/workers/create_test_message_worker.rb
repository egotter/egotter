class CreateTestMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def timeout_in
    1.minute
  end

  # options:
  #   error_class
  #   error_message
  #   enqueued_at
  #   create_test_report_request_id
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    if options['error_class']
      # If the error is that the DM cannot be sent, an additional exception occurs here.
      TestMessage.need_fix(user.id, options['error_class'], options['error_message']).deliver!
    else
      TestMessage.ok(user.id).deliver!
    end
  rescue => e
    logger.warn "¥#{e.class} #{e.message} #{user_id} #{options.inspect}"

    if TemporaryDmLimitation.temporarily_locked?(e)
      if TemporaryDmLimitation.you_have_blocked?(e)
        CreateBlockedUserWorker.perform_async(user.uid, user.screen_name)
      end
    elsif TemporaryDmLimitation.not_allowed_to_access_or_delete_dm?(e)
    else
      logger.info e.backtrace.join("\n")
    end

    # Overwrite existing error_class and error_message
    log(options).update(status: false, error_class: e.class, error_message: e.message)
  end

  def log(options)
    CreateTestReportLog.find_by(request_id: options['create_test_report_request_id'])
  end
end
