class CreateThankYouMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  TEXT = [
      'お役に立てて光栄です！',
      'どういたしまして！',
      'いえいえ、また何かあったら何でも言ってください！',
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
    User.egotter.api_client.create_direct_message(uid, message)
  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    end
  end
end
