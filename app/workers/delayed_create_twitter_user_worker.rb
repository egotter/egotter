class DelayedCreateTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 3, backtrace: false

  sidekiq_retry_in do |count|
    30.minutes + rand(10.minutes)
  end

  def perform(values = {})
    slept = false
    while (queue = Sidekiq::Queue.new('CreateTwitterUserWorker')).size > BUSY_QUEUE_SIZE
      logger.warn "I will sleep. Bye! size: #{queue.size}"
      slept = true
      sleep 10.minutes
    end

    logger.warn 'Good morning. I will retry.' if slept

    super
  end

  private

  def handle_retryable_exception(values, ex)
    if ex.class == Twitter::Error::TooManyRequests
      logger.warn "#{ex.message} Reset in #{ex&.rate_limit&.reset_in} seconds #{values['user_id']} #{values['uid']}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
    else
      logger.warn "#{ex.message} #{values['user_id']} #{values['uid']}"
    end

    raise ex
  end
end
