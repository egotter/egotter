class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    log = SearchLog.create!(attrs)
    UpdateSearchLogWorker.perform_async(log.id)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{attrs.inspect}"
  end
end
