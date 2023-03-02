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
  #   text
  def perform(uid, options = {})
    message = generate_message(options['text'])
    User.egotter.api_client.create_direct_message(uid, message)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  ensure
    Airbag.info 'OpenAI response', worker: self.class, input: options['text'], output: message
  end

  private

  def generate_message(text)
    OpenAiClient.new.chat(text)
  rescue => e
    Airbag.exception e, text: text
    TEXT.sample + Kaomoji::KAWAII.sample
  end
end
