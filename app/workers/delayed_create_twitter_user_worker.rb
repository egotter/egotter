class DelayedCreateTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 3, backtrace: false, dead: true

  sidekiq_retry_in do |count|
    egotter_retry_in
  end

  def perform(values = {})
    # slept = false
    # while (queue = Sidekiq::Queue.new('CreateTwitterUserWorker')).size > BUSY_QUEUE_SIZE
    #   logger.info "I will sleep. Bye! size: #{queue.size}"
    #   slept = true
    #   sleep 3.minutes
    # end
    #
    # logger.info 'Good morning. I will retry.' if slept

    super
  end

  private

  def handle_retryable_exception(values, ex)
    params_str = "#{values['user_id']} #{values['uid']} #{values['device_type']} #{values['auto']}"

    if ex.class == Twitter::Error::TooManyRequests
      sleep_seconds = ex&.rate_limit&.reset_in.to_i + 1
      logger.warn "Retry(too many requests) after #{sleep_seconds} seconds. #{params_str}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
      DelayedCreateTwitterUserWorker.perform_in(sleep_seconds.seconds, values)
    else
      sleep_seconds = egotter_retry_in
      logger.warn "Retry(#{ex.class.name.demodulize}) after #{sleep_seconds} seconds. #{params_str}"
      DelayedCreateTwitterUserWorker.perform_in(sleep_seconds, values)
    end
  end
end
