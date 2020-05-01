class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    log = SearchLog.create!(attrs)

    if log.with_login?
      CreateAccessDayWorker.perform_async(log.user_id)
    end

    unless log.crawler?
      UpdateFootprintsWorker.perform_async(log.id, user_id: log.user_id) if log.with_login?
      UpdateVisitorWorker.perform_async(log.slice(:session_id, :user_id, :created_at))
    end
  rescue => e
    logger.warn "#{e.inspect} #{attrs.inspect}"
  end
end
