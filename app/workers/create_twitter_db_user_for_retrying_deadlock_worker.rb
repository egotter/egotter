class CreateTwitterDBUserForRetryingDeadlockWorker < CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'retry_low', retry: 0, backtrace: false

  def after_skip(uids, options = {})
    SkippedCreateTwitterDBUserForRetryingDeadlockWorker.perform_async(uids, options)
  end
end
