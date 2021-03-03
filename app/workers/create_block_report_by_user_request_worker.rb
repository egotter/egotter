class CreateBlockReportByUserRequestWorker < CreateBlockReportWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_in(*args)
    3.seconds
  end
end
