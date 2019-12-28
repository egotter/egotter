class CreateTestMessageWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
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
  #   create_test_report_request_id
  def perform(user_id, options = {})
    user = User.find(user_id)
    unless user.authorized?
      log(options).update(status: false, error_class: Unauthorized, error_message: "Direct message not sent #{user_id} #{options.inspect}")
      return
    end

    error = options['error']

    if error['name'] == 'CreateTestReportRequest::CannotSendDirectMessageAtAll'
      message = "Can not send a direct message at all #{user_id}"
      logger.warn message
      send_message_to_slack(message, title: error['name'], user_id: user_id)
      return
    end

    if send_dm_cannot_send_message(user, error['name'])
      send_message_to_slack(message, title: error['name'], user_id: user_id)
      return
    end

    if error['name']
      dm = TestMessage.need_fix(user.id, error['name'], error['message']).deliver!
      send_message_to_slack(dm.text, title: 'need_fix', user_id: user_id)
    else
      dm = TestMessage.ok(user.id).deliver!
      send_message_to_slack(dm.text, title: 'ok', user_id: user_id)

      request = CreatePromptReportRequest.create(user_id: user.id)
      ForceCreatePromptReportWorker.perform_in(10.seconds, request.id, user_id: user.id)
    end

  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    notify_airbrake(e, user_id: user_id, options: options)

    # Overwrite existing error_class and error_message
    log(options).update(status: false, error_class: e.class, error_message: e.message)
  end

  def send_dm_cannot_send_message(user, error_name)
    template = Rails.root.join('app/views/test_reports/test.ja.text.erb')

    if error_name == 'CreateTestReportRequest::CannotSendDirectMessageFromUser'
      message = ERB.new(template.read).result_with_hash(
          from: user.screen_name,
          to: User.egotter.screen_name,
          egotter_url: Rails.application.routes.url_helpers.root_url(via: 'test_report_cannot_send'),
      )
      DirectMessageClient.new(User.egotter.api_client.twitter).
          create_direct_message(user.uid, message)

      true
    elsif error_name == 'CreateTestReportRequest::CannotSendDirectMessageFromEgotter'
      message = ERB.new(template.read).result_with_hash(
          from: User.egotter.screen_name,
          to: user.screen_name,
          egotter_url: Rails.application.routes.url_helpers.root_url(via: 'test_report_cannot_send'),
      )
      DirectMessageClient.new(user.api_client.twitter).
          create_direct_message(User::EGOTTER_UID, message)

      true
    else
      false
    end
  end

  def send_message_to_slack(text, title: nil, user_id: nil)
    if title == 'ok'
      text = ''
      title = "#{title} #{user_id}"
    else
      title = "#{title} #{user_id} #{User.find(user_id).inspect}"
    end
    SlackClient.test_messages.send_message(text, title: title)
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
  end

  def log(options)
    CreateTestReportLog.find_or_initialize_by(request_id: options['create_test_report_request_id'])
  end
end
