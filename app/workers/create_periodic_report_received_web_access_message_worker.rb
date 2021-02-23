class CreatePeriodicReportReceivedWebAccessMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    アクセスありがとうございます。
    通知の送信回数が回復しました。(๑•ᴗ•๑)

    残り送信回数：4回

    #egotter
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    30.seconds
  end

  # options:
  def perform(uid, options = {})
    if (user = User.select(:id).find_by(uid: uid))
      if PeriodicReport.access_interval_too_long?(user)
        message = PeriodicReport.access_interval_too_long_message(user.id).message
        User.egotter.api_client.create_direct_message_event(uid, message)
      else
        User.egotter.api_client.create_direct_message_event(uid, MESSAGE)
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
