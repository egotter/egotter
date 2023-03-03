class CreateQuestionMessageWorker
  include Sidekiq::Worker
  include ChatUtil
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    ご連絡ありがとうございます。回答が必要なお問い合わせでしょうか？ もしそうであれば、@egotter_cs へご連絡ください。

    #egotter
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.seconds
  end

  # options:
  #   text
  #   inquiry or question
  def perform(uid, options = {})
    if options['inquiry']
      User.egotter.api_client.create_direct_message(uid, MESSAGE)
    elsif options['question']
      message = generate_chat(options['text'])
      replies = [PeriodicReport::QUICK_REPLY_INQUIRY]
      event = DirectMessageEvent.build_with_replies(uid, message, replies)
      User.egotter.api_client.create_direct_message_event(event: event)
    end
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
