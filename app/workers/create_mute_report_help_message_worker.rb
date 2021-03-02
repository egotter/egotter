class CreateMuteReportHelpMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    3.seconds
  end

  # options:
  def perform(user_id, options = {})
    # The user's existence is confirmed in MuteReportResponder.
    user = User.find(user_id)
    message = MuteReport.help_message(user)
    event = MuteReport.build_direct_message_event(user.uid, message, quick_replies: [MuteReport::QUICK_REPLY_SEND])
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end
