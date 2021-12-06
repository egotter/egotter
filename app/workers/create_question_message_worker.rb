class CreateQuestionMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  MESSAGE = <<~TEXT
    何かご質問でしょうか？ お返事が必要な場合は @egotter_cs までご連絡ください。
    （質問の送り先は ego_tter ではなく egotter_cs です）
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
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
