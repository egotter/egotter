class CreateTwitterDBUserForRetryableErrorWorker < CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'retry_low', retry: 0, backtrace: false
end
