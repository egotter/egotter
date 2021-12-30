class ImportTwitterDBUserForRetryingDeadlockWorker < ImportTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'retry_low', retry: 0, backtrace: false

  def after_skip(users, options = {})
    SkippedImportTwitterDBUserForRetryingDeadlockWorker.perform_async(users, options)
  end
end
