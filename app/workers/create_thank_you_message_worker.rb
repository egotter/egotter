class CreateThankYouMessageWorker
  include Sidekiq::Worker
  include ChatUtil
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGES = [
      'いいよ！',
      'いいよー！',
      'カンゲキだよ！',
      'どういたしまして！',
      'いいえー！嬉しいー！',
      'どういたしまして〜♪',
      'どういたしまして〜！',
      'どういたしましてー！',
      'いいよー！気軽にどうぞ♪',
      'うん、どういたしまして！',
      'いいえ、どういたしまして！',
      'いえいえ、どういたしまして！',
      'うんうん、どういたしまして！',
      'どういたしまして！嬉しいな！',
      'どういたしまして！うれしいな♪',
      'どういたしまして！嬉しいな〜！',
      'どういたしまして！嬉しいなー♪',
      'どういたしまして！嬉しいなー！',
      'どういたしましてー！ありがとね！',
      'どういたしまして！嬉しいなぁ〜！',
      'こちらこそありがとー！嬉しいなー！',
      'どういたしましてー！嬉しいなぁ〜！',
      'どういたしまして！なんでも聞いてね！',
      'どういたしまして！めっちゃ嬉しいさ！',
      'どういたしまして！ホントありがとー！',
      'どういたしまして！ちょっと嬉しいかも！',
      'どういたしまして！めっちゃ嬉しいわ〜！',
      'どういたしまして！めっちゃ嬉しいわー！',
      'どういたしまして！めっちゃ嬉しいわ～！',
      'どういたしまして！めちゃくちゃ嬉しいよ！',
      'どういたしまして！めっちゃ感謝するぜー！',
  ]

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    30.seconds
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
