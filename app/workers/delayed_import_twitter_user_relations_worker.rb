class DelayedImportTwitterUserRelationsWorker < ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 3, backtrace: false

  sidekiq_retry_in do |count|
    30.minutes + rand(10.minutes)
  end

  def perform(user_id, uid)
    slept = false
    while (queue = Sidekiq::Queue.new('ImportTwitterUserRelationsWorker')).size > BUSY_QUEUE_SIZE
      logger.warn "I will sleep. Bye! size: #{queue.size}"
      slept = true
      sleep 10.minutes
    end

    logger.warn 'Good morning. I will retry.' if slept

    super
  end

  private

  def handle_retryable_exception(user_id, uid, ex)
    if ex.class == Twitter::Error::TooManyRequests
      logger.warn "#{ex.message} Reset in #{ex&.rate_limit&.reset_in} seconds #{user_id} #{uid}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
    else
      logger.warn "#{ex.message} #{user_id} #{uid}"
    end

    raise ex
  end
end
