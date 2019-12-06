class CreateTestMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def after_skip(user_id, options = {})
    log(Hashie::Mash.new(options)).update(status: false, error_class: DuplicateJobSkipped, error_message: "Direct message not sent #{user_id} #{options.inspect}")
  end

  def timeout_in
    1.minute
  end

  class Unauthorized < StandardError
  end

  class DuplicateJobSkipped < StandardError
  end

  # options:
  #   error_class
  #   error_message
  #   enqueued_at
  #   create_test_report_request_id
  def perform(user_id, options = {})
    user = User.find(user_id)
    unless user.authorized?
      log(options).update(status: false, error_class: Unauthorized, error_message: "Direct message not sent #{user_id} #{options.inspect}")
      return
    end

    template = Rails.root.join('app/views/test_reports/test.ja.text.erb')
    message = ERB.new(template.read).result

    begin
      # If the error is that the DM cannot be sent, an additional exception occurs here.
      dm_client = DirectMessageClient.new(user.api_client.twitter)
      dm_client.create_direct_message(User::EGOTTER_UID, message)
    rescue => e
      dm = TestMessage.permission_level_not_enough(user.id).deliver!
      send_message_to_slack(dm.text, title: 'plne')
    else
      if options['error_class']
        if [CreatePromptReportRequest::TooShortSendInterval, CreatePromptReportRequest::TooShortRequestInterval].map(&:to_s).include?(options['error_class'])
          dm = TestMessage.ok(user.id).deliver!
          send_message_to_slack(dm.text, title: 'ok')
        else
          dm = TestMessage.need_fix(user.id, options['error_class'], options['error_message']).deliver!
          send_message_to_slack(dm.text, title: 'need_fix')
        end
      else
        dm = TestMessage.ok(user.id).deliver!
        send_message_to_slack(dm.text, title: 'ok')

        request = CreatePromptReportRequest.create(user_id: user.id)
        ForceCreatePromptReportWorker.perform_in(10.seconds, request.id, user_id: user.id)
      end
    end

  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    logger.info e.backtrace.join("\n")

    # Overwrite existing error_class and error_message
    log(options).update(status: false, error_class: e.class, error_message: e.message)
  end

  def send_message_to_slack(text, title: nil)
    SlackClient.test_messages.send_message(text, title: "`#{title}`")
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
  end

  def log(options)
    CreateTestReportLog.find_or_initialize_by(request_id: options['create_test_report_request_id'])
  end
end
