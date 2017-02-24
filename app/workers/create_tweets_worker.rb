class CreateTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(keyword)
    json = Bot.api_client.search(keyword, count: 10).take(5).to_json
    Util::TweetsCache.new(Redis.client).set(keyword, json)
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{keyword}"
  end
end
