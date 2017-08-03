class CreateCrawlerLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(attrs)
    CrawlerLog.create!(attrs)
  rescue => e
    logger.warn "#{self.class}: #{e.class} #{e.message} #{attrs.inspect}"
  end
end
