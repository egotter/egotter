class StopAllReportsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(user_id, options = {})
    unless StopPeriodicReportRequest.exists?(user_id: user_id)
      StopPeriodicReportRequest.create(user_id: user_id)
    end

    unless StopSearchReportRequest.exists?(user_id: user_id)
      StopSearchReportRequest.create(user_id: user_id)
    end

    unless StopBlockReportRequest.exists?(user_id: user_id)
      StopBlockReportRequest.create(user_id: user_id)
    end

    unless StopMuteReportRequest.exists?(user_id: user_id)
      StopMuteReportRequest.create(user_id: user_id)
    end
  rescue => e
    handle_worker_error(e, user_id: user_id, **options)
  end
end
