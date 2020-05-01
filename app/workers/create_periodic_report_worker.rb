class CreatePeriodicReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    1.minute
  end

  # options:
  def perform(request_id, options = {})
    if GlobalDirectMessageLimitation.new.limited?
      SkippedCreatePeriodicReportWorker.perform_async(request_id, options)
      return
    end

    request = CreatePeriodicReportRequest.find(request_id)
    CreatePeriodicReportTask.new(request).start!

  rescue => e
    notify_airbrake(e, request_id: request_id, options: options)
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
