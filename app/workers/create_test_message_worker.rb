class CreateTestMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def after_skip(user_id, options = {})
    log(Hashie::Mash.new(options)).update(status: false, error_class: CreatePromptReportRequest::DuplicateJobSkipped, error_message: '')
  end

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
    unless user.authorized?
      log(options).update(status: false, error_class: 'Unauthorized', error_message: self.class)
      return
    end

    # If the error is that the DM cannot be sent, an additional exception occurs here.
    begin
      dm_client = DirectMessageClient.new(user.api_client.twitter)
      dm_client.create_direct_message(User::EGOTTER_UID, 'Start sending test message.')
    rescue => e
      TestMessage.permission_level_not_enough(user.id).deliver!
    else
      if options['error_class']
        TestMessage.need_fix(user.id, options['error_class'], options['error_message']).deliver!
      else
        TestMessage.ok(user.id).deliver!

        request = CreatePromptReportRequest.create(user_id: user.id)
        ForceCreatePromptReportWorker.perform_in(10.seconds, request.id, user_id: user.id)
      end
    end

  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{options.inspect}"

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
    CreateTestReportLog.find_or_initialize_by(request_id: options['create_test_report_request_id'])
  end
end
