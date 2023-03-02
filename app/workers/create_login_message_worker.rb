class CreateLoginMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    「ツイッター連携ログインに失敗する」というお問い合わせでしょうか？

     もしそうであれば、ツイッターアプリのバグが原因です…！ このバグは世界中で起きています。

    ・ログイン失敗の解決策
    @egotter_cs のプロフィール固定ツイートの手順をお試しください。ブラウザのプライベートモードを使うことが重要です。

    ・どうしても解決しない場合
    下記のチェックリストをご確認ください。申し訳ないことに現状これしかできることがありません…。

    1. @egotter_cs のプロフィール固定ツイートは見ましたか？
    2. ブラウザのプライベートモードを使っていますか？（必須です）
    3. プライベートモードのタブを事前に全て閉じましたか？（必須です）
    4. ツイッターアプリのDMからリンクを開いてますか？（DMから開くと失敗します）
    5. 「Twitterアプリで開く」をキャンセルしましたか？（アプリから開くと失敗します）
    6. ツイッター自体へのログインはできますか？
    7. ツイッターの ID/PASS は合っていますか？

    もし何か連絡する場合は @egotter_cs に送ってください。

    #egotter
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    10.minutes
  end

  # options:
  def perform(uid, options = {})
    user = options['from_cs'] ? User.egotter_cs : User.egotter
    user.api_client.create_direct_message(uid, MESSAGE)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
