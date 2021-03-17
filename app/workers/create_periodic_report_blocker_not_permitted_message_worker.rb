class CreatePeriodicReportBlockerNotPermittedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    @ego_tter をブロックしているため、全ての通知とWebサイトの利用が制限されています。

    Webサイトを今後も利用する場合は、有料プランの購入とブロックの解除が必要です。両方とも完了した後に @egotter_cs にDMで連絡してください。
    #egotter
  TEXT

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

    quick_replies = [PeriodicReport::QUICK_REPLY_SEND, BlockReport::QUICK_REPLY_SEND, MuteReport::QUICK_REPLY_SEND]
    event = PeriodicReport.build_direct_message_event(user.uid, MESSAGE, quick_reply_buttons: quick_replies)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options}"
      logger.info e.backtrace.join("\n")
    end
  end
end