class CreateUserRequestedPeriodicReportWorker < CreatePeriodicReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'report_high', retry: 0, backtrace: false

  def unique_in(*args)
    1.second
  end
end
