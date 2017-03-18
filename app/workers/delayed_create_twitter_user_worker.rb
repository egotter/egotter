class DelayedCreateTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  private

  def before_perform(*args)
    while (queue = Sidekiq::Queue.new('CreateTwitterUserWorker')).size > CreateTwitterUserWorker::BUSY_QUEUE_SIZE
      logger.warn "I will sleep. Bye! #{queue.size}"
      sleep 10.minutes
    end
    true
  end
end
