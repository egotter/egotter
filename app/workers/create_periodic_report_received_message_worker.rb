class CreatePeriodicReportReceivedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    お返事ありがとうございます。
    通知の送信回数が回復しました。(๑•ᴗ•๑)

    残り送信回数：4回
    有効期限：24時間
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
    User.egotter.api_client.create_direct_message_event(uid, MESSAGE)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
