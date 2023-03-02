class CreateGreetingOkMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    よし！
  TEXT

  def unique_key(uid, options = {})
    uid
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  #   text
  def perform(uid, options = {})
    User.egotter.api_client.create_direct_message(uid, MESSAGE + Kaomoji::KAWAII.sample)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
