class CreateLoginMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    「複数アカウントを持っている場合にログインできない」というお問い合わせでしょうか？

     もしそうであれば、ツイッターアプリのバグが原因です…！ @egotter_cs のプロフィール固定ツイートの手順をお試しください。

    他にも何か質問がある場合は、@egotter_cs の方にご連絡ください。

    ※ 今DMしているのは ego_tter です。アカウントが異なります。
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
