class DelayedCreateTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 3, backtrace: false, dead: true

  sidekiq_retry_in do |count|
    30.minutes + rand(10.minutes)
  end

  def perform(values = {})
    slept = false
    while (queue = Sidekiq::Queue.new('CreateTwitterUserWorker')).size > BUSY_QUEUE_SIZE
      logger.info "I will sleep. Bye! size: #{queue.size}"
      slept = true
      sleep 3.minutes
    end

    logger.info 'Good morning. I will retry.' if slept

    super
  end

  private

  def handle_retryable_exception(values, ex)
    if ex.class == Twitter::Error::TooManyRequests
      sleep_time = ex&.rate_limit&.reset_in.to_i + 1
      logger.warn "#{ex.message} Reset in #{sleep_time} seconds #{values['user_id']} #{values['uid']}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
      logger.warn 'I will sleep. Bye!'
      sleep sleep_time
      logger.warn 'Good morning. I will retry.'
      DelayedCreateTwitterUserWorker.perform_in(30.minutes + rand(10.minutes), values)
    else
      logger.warn "#{ex.class} #{ex.message.truncate(100)} #{values['user_id']} #{values['uid']}"
      raise ex
    end
  end
end
