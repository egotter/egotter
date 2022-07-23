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
    buttons = [PeriodicReport::QUICK_REPLY_RECEIVED]
    User.egotter.api_client.send_report(uid, message, buttons)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
