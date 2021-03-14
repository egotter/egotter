class CreatePeriodicReportReceivedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    お返事ありがとうございます。
    通知の送信回数が回復しました。(๑•ᴗ•๑)

    残り送信回数：4回
    有効期限：24時間

    ・残り送信回数って何？
    えごったーからあなたにDMを送れる残りの回数です。ツイッターのDMは送信回数に制限があり、DMを受け取るごとにその数値が回復します。

    ・有効期限って何？
    回復した送信回数は24時間以内に使わないと0になります。この期限のことです。

    ・なんでそんな仕組みなの？
    2019年8月に改定されたツイッター利用規約によりこの仕組みが世界的に適用されています。

    #egotter
  TEXT

  SIMPLE_MESSAGE = <<~TEXT
    通知の送信回数が回復しました。
    ・残り送信回数：4回
    ・有効期限：24時間
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
    user = User.select(:id).find_by(uid: uid)

    if PeriodicReportReceivedMessageConfirmation.exists?(user_id: user.id)
      message = SIMPLE_MESSAGE
    else
      message = MESSAGE
      PeriodicReportReceivedMessageConfirmation.create(user_id: user.id)
    end

    quick_replies = [PeriodicReport::QUICK_REPLY_SEND, BlockReport::QUICK_REPLY_SEND, MuteReport::QUICK_REPLY_SEND]
    event = PeriodicReport.build_direct_message_event(uid, message, quick_reply_buttons: quick_replies)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  def disposable_report?
    true
  end
end
