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
      buttons = [PeriodicReport::QUICK_REPLY_SEND, BlockReport::QUICK_REPLY_SEND, MuteReport::QUICK_REPLY_SEND]
      User.egotter.api_client.send_report(uid, MESSAGE, buttons)
    end
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end

  private

  def build_second_message(user)
    recipient_name = (MessageEncryptor.new.encrypt(user.screen_name) rescue nil)
    url = Rails.application.routes.url_helpers.access_confirmations_url(user_token: user.user_token, recipient_name: recipient_name, share_dialog: 1, follow_dialog: 1, purchase_dialog: 1, og_tag: false, via: 'web_access_received_message')
    ERB.new(SECOND_MESSAGE).result_with_hash(url: url, user: user.screen_name)
  end
end
