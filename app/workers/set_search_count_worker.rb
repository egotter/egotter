class SetSearchCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def perform
    count =
        SearchLog.where(created_at: 1.day.ago..Time.zone.now)
            .where(controller: 'timelines', action: 'show')
            .size
    ::Util::SearchCountCache.set(count)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
  end
end
