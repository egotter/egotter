class CreateBlockReportAccessIntervalTooLongMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    return if user.unauthorized_or_expire_token?

    BlockReport.send_start_message(user)
    message = BlockReport.access_interval_too_long_message(user)
    replies = [BlockReport::QUICK_REPLY_SEND, BlockReport::QUICK_REPLY_STOP, BlockReport::QUICK_REPLY_HELP]
    event = DirectMessageEvent.build_with_replies(user.uid, message, replies)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, user_id: user_id, options: options
    end
  end
end
