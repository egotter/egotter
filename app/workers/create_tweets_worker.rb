class CreateTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(keyword)
    tweets = User.admin.api_client.search(keyword, count: 10).take(10)
    SearchedTweets.set(keyword, tweets.to_json)
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{keyword}"
  end
end
