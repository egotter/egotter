class CreateTestReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    10.minutes
  end

  def timeout_in
    1.minute
  end

  # options:
  #   enqueued_at
  def perform(request_id, options = {})
    request = CreateTestReportRequest.find(request_id)

    begin
      CreateTestReportTask.new(request).start!
      CreateTestMessageWorker.perform_async(request.user_id, enqueued_at: Time.zone.now, create_test_report_request_id: request.id)
    rescue CreatePromptReportRequest::Error => e
      # At this point, I don't know if DM can be sent.
      CreateTestMessageWorker.perform_async(request.user_id, error_class: e.class, error_message: e.message.truncate(100), enqueued_at: Time.zone.now, create_test_report_request_id: request.id)
    end

  rescue => e
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
