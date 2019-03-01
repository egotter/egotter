class SetSearchCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform
    queue = RunningQueue.new(self.class)
    return if queue.exists?(-1)
    queue.add(-1)

    count =
        SearchLog.where(created_at: 1.day.ago..Time.zone.now)
            .where(controller: 'timelines', action: 'show')
            .size
    Util::SearchCountCache.set(count)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
  end
end
