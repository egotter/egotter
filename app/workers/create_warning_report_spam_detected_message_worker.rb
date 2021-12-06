class CreateWarningReportSpamDetectedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    1.minute
  end

  # options:
  def perform(uid, options = {})
    message = WarningReport.spam_detected_message
    event = WarningReport.build_direct_message_event(uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)

  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
