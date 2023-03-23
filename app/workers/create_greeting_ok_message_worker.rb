class CreateGreetingOkMessageWorker
  include Sidekiq::Worker
  include ChatUtil
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGES = [
      '届いてるよ！',
      '届きました！',
      'お願いします！',
      '届いています！',
      '届いているよ！',
      '届きましたよ！',
      '届いていますよ！',
      '届いてますよー！',
      '届いていますよ〜！',
      '届いていますよー！',
      '届きましたよ〜！！ どうしたんですか？何かお探しですか？',
      'はい、届いていますよ！',
      'はい、届いてますよ〜！',
      '了解！届いていますよ！',
      '届いてます！ありがと！',
      'はい、届いていますよー！',
      'ほーんとーだー！ありがとー！',
      '了解！メッセージが届いたよ！',
      'うん、メッセージが届きましたよ！',
      '届いてますよ〜！なにかお困りですか？',
      'はい、ちゃんと届いてますよ！ありがとう！',
      'ちょっと待っててね！届いたらすぐに教えるね！',
      '届いてるよ！めっちゃ早く返信しちゃった（笑）',
      'はい、メッセージを受信しました。分かりました。',
      '届いてますよ！何かお困りのことがあるんですか？',
      '了解！届いていますよ～！何かお手伝いできますか？',
      '届いていますよ！何かお力になれることがありますか？',
      'ええ、メッセージはちゃんと届いてるよ！ありがとうございます！',
      '届いてますよー！メッセージを受け取れました！何かお力になりますか？',
      'はい、届いていますよ！あなたのメッセージを読むことができました。何か質問があれば、答えますよ！',
      'わかりました！メッセージが届いたことを確認しました。何か問題がある場合は、遠慮なくお知らせくださいね！',
  ]

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  #   text
  def perform(uid, options = {})
    User.egotter.api_client.create_direct_message(uid, MESSAGES.sample)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
