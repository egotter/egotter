class CreatePrettyIconMessageWorker
  include Sidekiq::Worker
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
    30.seconds
  end

  # options:
  def perform(uid, options = {})
    message = TEXT.sample + Kaomoji::KAWAII.sample
    User.egotter.api_client.create_direct_message_event(uid, message)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
