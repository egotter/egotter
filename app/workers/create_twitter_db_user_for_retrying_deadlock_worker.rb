# I want to print this class name to sidekiq.log.
class CreateTwitterDBUserForRetryingDeadlockWorker < CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false
end
