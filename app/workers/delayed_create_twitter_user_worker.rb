class DelayedCreateTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 3, backtrace: false, dead: true

  sidekiq_retry_in do |count|
    egotter_retry_in
  end

  def perform(values = {})
    super
  end

  private

  def handle_retryable_exception(values, ex)
    params_str = "#{values['user_id']} #{values['uid']} #{values['device_type']} #{values['auto']}"

    sleep_seconds =
      (ex.class == Twitter::Error::TooManyRequests) ? (ex&.rate_limit&.reset_in.to_i + 1).seconds : egotter_retry_in

    logger.warn "Retry(#{ex.class.name.demodulize}) after #{sleep_seconds} seconds. #{params_str}"
    DelayedCreateTwitterUserWorker.perform_in(sleep_seconds, values)
  end
end
