class CreateMuteReportByUserRequestWorker < CreateMuteReportWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_in(*args)
    1.second
  end
end
