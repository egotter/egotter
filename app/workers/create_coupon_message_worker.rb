class CreateCouponMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    「定期購読プランの割引クーポン」のお問い合わせでしょうか？

     もしそうであれば、@egotter_cs にご連絡ください。

    ※ 連絡先は @egotter_cs です。ego_tter ではないです。
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    10.minutes
  end

  # options:
  def perform(uid, options = {})
    User.egotter.api_client.create_direct_message(uid, MESSAGE)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
