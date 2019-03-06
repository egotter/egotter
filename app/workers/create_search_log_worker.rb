class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    log = SearchLog.create!(attrs)

    unless log.crawler?
      UpdateSearchLogWorker.perform_async(log.id)
      UpdateVisitorWorker.perform_async(log.slice(:session_id, :user_id, :created_at))
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{attrs.inspect}"
  end
end
