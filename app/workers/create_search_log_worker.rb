class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    log = SearchLog.create!(attrs)

    unless log.crawler?
      UpdateVisitorWorker.perform_async(log.slice(:session_id, :user_id, :created_at))
    end
  rescue => e
    logger.warn "#{e.inspect} attrs=#{attrs.inspect}"
  end
end
