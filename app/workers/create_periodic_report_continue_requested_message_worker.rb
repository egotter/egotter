class CreatePeriodicReportContinueRequestedMessageWorker
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

    message = PeriodicReport.continue_requested_message.message
    buttons = [PeriodicReport::QUICK_REPLY_SEND, BlockReport::QUICK_REPLY_SEND, MuteReport::QUICK_REPLY_SEND]
    User.egotter.api_client.send_report(user.uid, message, buttons)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} user_id=#{user_id} options=#{options}", backtrace: e.backtrace
    end
  end
end
