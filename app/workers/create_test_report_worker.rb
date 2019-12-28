class CreateTestReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    1.minute
  end

  def timeout_in
    1.minute
  end

  # options:
  def perform(request_id, options = {})
    request = CreateTestReportRequest.find(request_id)

    task = CreateTestReportTask.new(request)
    task.start!

    message_options = {create_test_report_request_id: request.id, error: task.error}
    CreateTestMessageWorker.perform_async(request.user_id, message_options)

  rescue => e
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    notify_airbrake(e, request_id: request_id, options: options)
  end
end
