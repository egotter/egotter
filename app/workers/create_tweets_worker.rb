class CreateTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(keyword, ttl)
    json = Bot.api_client.search(keyword, count: 10).take(5).to_json
    Redis.client.setex("tweets_cache_for:#{keyword}", ttl, json)
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{keyword} #{ttl}"
  end
end
