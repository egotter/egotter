class CreateQuestionMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    何かご質問でしょうか？ お返事が必要な場合は @egotter_cs までご連絡ください。
    ( ˶ｰ̀֊ｰ́ )੭"

    お返事が必要な質問は @ego_tter ではなく @egotter_cs にお送りください。

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
    User.egotter.api_client.create_direct_message(uid, MESSAGE)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
