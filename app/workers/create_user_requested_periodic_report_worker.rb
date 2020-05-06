# I want to print this class name to sidekiq.log.
class CreateUserRequestedPeriodicReportWorker < CreatePeriodicReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false
end
