# I want to print this class name to sidekiq.log.
class CreateEgotterRequestedPeriodicReportWorker < CreatePeriodicReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_in
    1.second
  end

end
