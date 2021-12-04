class CreateTwitterDBUserForRetryableErrorWorker < CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'retry_low', retry: 0, backtrace: false

  def after_skip(uids, options = {})
    SkippedCreateTwitterDBUserForRetryableErrorWorker.perform_async(uids, options)
  end
end
