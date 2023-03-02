class CreatePrettyIconMessageWorker
  include Sidekiq::Worker
  include ChatUtil
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  TEXT = [
      '褒めてくれたんですよね？ ありがとうございます！',
      '褒めてくれたんですよね？ 嬉しいです！',
  ]

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.seconds
  end

  # options:
  #   text
  def perform(uid, options = {})
    message = generate_chat(options['text'], default: TEXT.sample + Kaomoji::KAWAII.sample)
    User.egotter.api_client.create_direct_message(uid, message)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
