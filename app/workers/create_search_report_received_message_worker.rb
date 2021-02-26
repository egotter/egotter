class CreateSearchReportReceivedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    お返事ありがとうございます。
    DMの送信回数が回復しました。(๑•ᴗ•๑)

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

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.seconds
  end

  # options:
  def perform(uid, options = {})
    unless (user = User.select(:id).find_by(uid: uid))
      # TODO Send a message
    end

    quick_reply_buttons = PeriodicReport.general_quick_reply_options
    event = SearchReport.build_direct_message_event(uid, MESSAGE, quick_replies: quick_reply_buttons)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
