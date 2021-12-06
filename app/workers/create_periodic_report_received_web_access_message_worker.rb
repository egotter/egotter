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

  SECOND_MESSAGE = <<~TEXT
    アクセス履歴が見付かりませんでした。

    ↓↓↓
    <%= url %>
    ↑↑↑

    えごったーのWebサイトに <%= user %> さんがアクセスすればOKです。

    ログインし直しが面倒な場合は、いつも使っているブラウザからもアクセスしてみてください。

    分からないところがありますか？ お困りの際は @egotter_cs までお気軽にご質問ください。
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
    user = User.find_by(uid: uid)

    if PeriodicReport.access_interval_too_long?(user)
      # CreatePeriodicReportAccessIntervalTooLongMessageWorker.perform_async(user.id)
      User.egotter.api_client.create_direct_message(uid, build_second_message(user))
    else
      quick_replies = [PeriodicReport::QUICK_REPLY_SEND, BlockReport::QUICK_REPLY_SEND, MuteReport::QUICK_REPLY_SEND]
      event = PeriodicReport.build_direct_message_event(uid, MESSAGE, quick_reply_buttons: quick_replies)
      User.egotter.api_client.create_direct_message_event(event: event)
    end
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end

  private

  def build_second_message(user)
    url = Rails.application.routes.url_helpers.access_confirmations_url(user_token: user.user_token, share_dialog: 1, follow_dialog: 1, purchase_dialog: 1, og_tag: false, via: 'web_access_received_message')
    ERB.new(SECOND_MESSAGE).result_with_hash(url: url, user: user.screen_name)
  end
end
