class CreateQuestionMessageWorker
  include Sidekiq::Worker
  include ChatUtil
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT

    ------------------------------------

    何かご質問でしょうか？ お返事が必要な場合は @egotter_cs までご連絡ください。

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
  #   text
  def perform(uid, options = {})
    message = generate_chat(options['text']) + "\n\n" + MESSAGE
    User.egotter.api_client.create_direct_message(uid, message)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
