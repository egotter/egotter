class CreateMuteReportStopRequestedWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    3.seconds
  end

  def timeout_in
    10.seconds
  end

  # options:
  def perform(user_id, options = {})
    # The user's existence is confirmed in MuteReportResponder.
    user = User.find(user_id)
    message = MuteReport.stopped_message(user)
    event = MuteReport.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, user_id: user_id, options: options
    end
  end
end
