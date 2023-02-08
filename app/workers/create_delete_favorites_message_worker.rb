class CreateDeleteFavoritesMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~HTML
    いいねクリーナーのお問い合わせありがとうございます。よくある質問に回答します。
    (ᐡ _   _ ᐡ)

    いいねクリーナーを使っても、すべての「いいね」を一度で削除することはできません。ツイッターにいいね取得のバグがあるためです。

    例えば、1万件のいいねを削除したかったとしても、約#{DeleteFavoritesRequest::DESTROY_LIMIT}件を削除した後はしばらく残りのいいねが取得できなくなります。残りのいいねは一定期間後に取得できるようになるので、そのときに改めて残りのいいねを削除する必要があります。「一定期間後」がいつになるのかは分かりません。経験上は数日から2週間ほどかかります。

    さらに詳細については いいねクリーナー > よくある質問 をご覧になってください。

    #egotter
  HTML

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  def perform(uid, options = {})
    User.egotter_cs.api_client.create_direct_message(uid, MESSAGE)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
