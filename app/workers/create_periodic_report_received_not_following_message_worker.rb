class CreatePeriodicReportReceivedNotFollowingMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    フォローありがとうございます。
    通知の送信回数が回復しました。(๑•ᴗ•๑)

    残り送信回数：4回

    #egotter
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.seconds
  end

  # options:
  def perform(uid, options = {})
    if (user = User.select(:id, :uid).find_by(uid: uid))
      if EgotterFollower.exists?(uid: user.uid)
        quick_reply_buttons = PeriodicReport.general_quick_reply_options
        event = PeriodicReport.build_direct_message_event(uid, MESSAGE, quick_reply_buttons: quick_reply_buttons)
        User.egotter.api_client.create_direct_message_event(event: event)
      else
        CreatePeriodicReportNotFollowingMessageWorker.perform_async(user.id)
      end
    else
      # TODO Send a message
    end
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
