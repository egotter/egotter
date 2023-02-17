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
    @egotter_cs のプロフィール固定ツイートの方法を試してもログインに成功しない場合は、下記の質問への回答を @egotter_cs に送ってください。

    1. @egotter_cs のプロフィール固定ツイートは見ましたか？
    2. ツイッターアプリのDMからリンクを開きましたか？
    3. ブラウザのプライベートモードを使っていますか？
    4. プライベートモードのタブを事前に全て閉じましたか？
    5. 「Twitterアプリで開く」をキャンセルしましたか？
    6. ツイッター自体へのログインはできますか？
    7. ツイッターの ID/PASS は絶対に合っていますか？

    ※ 連絡先は @egotter_cs です。ego_tter ではないです。
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
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
