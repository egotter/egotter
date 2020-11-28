class InvalidateExpiredCredentialsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    1.minute
  end

  def expire_in
    1.minute
  end

  def _timeout_in
    1.minute
  end

  # options:
  def perform(options = {})
    Bot.invalidate_all_expired_credentials
  rescue => e
    handle_worker_error(e, user_id: user_id, **options)
  end
end
