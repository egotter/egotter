class CreateCrawlerLogWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    CrawlerLog.create!(attrs)
  end
end
