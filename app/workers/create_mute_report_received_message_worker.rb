class CreateMuteReportReceivedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    通知の送信回数が回復しました。
    ・残り送信回数：4回
    ・有効期限：24時間
    #egotter
  TEXT

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
    quick_replies = [PeriodicReport::QUICK_REPLY_SEND, BlockReport::QUICK_REPLY_SEND, MuteReport::QUICK_REPLY_SEND]
    event = MuteReport.build_direct_message_event(user.uid, MESSAGE, quick_replies: quick_replies)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end
