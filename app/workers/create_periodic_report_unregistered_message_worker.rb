# TODO Rename to CreateUnregisteredMessageWorker
class CreatePeriodicReportUnregisteredMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(uid, options = {})
    message = PeriodicReport.unregistered_message.message
    quick_reply_buttons = PeriodicReport.unregistered_quick_reply_options
    event = PeriodicReport.build_direct_message_event(uid, message, quick_reply_buttons: quick_reply_buttons)
    User.egotter.api_client.create_direct_message_event(event: event)

  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options}"
      Airbag.info e.backtrace.join("\n")
    end
  end
end
