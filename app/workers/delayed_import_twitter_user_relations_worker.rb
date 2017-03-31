class DelayedImportTwitterUserRelationsWorker < ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 3, backtrace: false, dead: true

  sidekiq_retry_in do |count|
    egotter_retry_in
  end

  def perform(user_id, uid, options = {})
    slept = false
    while (queue = Sidekiq::Queue.new('ImportTwitterUserRelationsWorker')).size > BUSY_QUEUE_SIZE
      logger.info "I will sleep. Bye! size: #{queue.size}"
      slept = true
      sleep(queue.size < 10 ? queue.size * 3 : 3.minutes)
    end

    logger.info 'Good morning. I will retry.' if slept

    super
  end

  private

  def handle_retryable_exception(ex, user_id, uid, twitter_user_id, options = {})
    if ex.class == Twitter::Error::TooManyRequests
      sleep_time = ex&.rate_limit&.reset_in.to_i + 1
      logger.warn "recover #{ex.message} Reset in #{sleep_time} seconds #{user_id} #{uid} #{twitter_user_id}"
      logger.info ex.backtrace.grep_v(/\.bundle/).join "\n"
      logger.warn 'I will sleep. Bye!'
      sleep sleep_time
      logger.warn 'Good morning. I will retry.'
    else
      logger.warn "recover #{ex.class.name.demodulize} #{user_id} #{uid} #{twitter_user_id}"
    end

    DelayedImportTwitterUserRelationsWorker.perform_in(egotter_retry_in, user_id, uid, options)
  end
end
