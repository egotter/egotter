class CreateTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(keyword)
    json = Bot.api_client.search(keyword, count: 10).take(5).to_json
    Util::TweetsCache.set(keyword, json)
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{keyword}"
  end
end
