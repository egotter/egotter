class CreateDeleteFavoritesMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~HTML
    いいねクリーナーのお問い合わせありがとうございます。よくある質問に回答します。
    (ᐡ _   _ ᐡ)

    ・一度に何件まで削除できますか？
    約#{DeleteFavoritesRequest::DESTROY_LIMIT}件まで一度に削除できます。

    ・もっとたくさんのいいねを削除できますか？
    一括削除を一定時間ごとに何回か繰り返せば削除できます。

    ・削除にどれくらい時間がかかりますか？
    削除処理が混み合っていなければ1〜10分ほどで削除は完了します。

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
    buttons = [InquiryResponseReport::QUICK_REPLY_RESOLVED, InquiryResponseReport::QUICK_REPLY_WAITING]
    User.egotter_cs.api_client.send_report(uid, MESSAGE, buttons)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
