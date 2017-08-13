class DelayedImportTwitterUserRelationsWorker < ImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 3, backtrace: false, dead: true

  sidekiq_retry_in do |count|
    egotter_retry_in
  end

  def perform(user_id, uid, options = {})
    super
  end

  private

  def handle_retryable_exception(ex, user_id, uid, twitter_user_id, options = {})
    params_str = "#{user_id} #{uid} #{twitter_user_id}"

    sleep_seconds =
      (ex.class == Twitter::Error::TooManyRequests) ? (ex&.rate_limit&.reset_in.to_i + 1).seconds : egotter_retry_in

    logger.warn "Retry(#{ex.class.name.demodulize}) after #{sleep_seconds} seconds. #{params_str}"
    DelayedImportTwitterUserRelationsWorker.perform_in(sleep_seconds, user_id, uid, options)
  end
end
