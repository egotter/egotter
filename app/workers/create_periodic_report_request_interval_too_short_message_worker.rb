class CreatePeriodicReportRequestIntervalTooShortMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    3.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)

    message = PeriodicReport.request_interval_too_short_message(user.id).message
    buttons = [PeriodicReport::QUICK_REPLY_RECEIVED]
    User.egotter.api_client.send_report(user.uid, message, buttons)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, user_id: user_id, options: options
    end
  end
end
