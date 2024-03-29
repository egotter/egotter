class CreateTweetCleanerMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.seconds
  end

  # options:
  def perform(uid, options = {})
    User.tweet_cleaner.api_client.create_direct_message(uid, 'OK ' + Kaomoji::KAWAII.sample)
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.exception e, uid: uid, options: options
    end
  end
end
