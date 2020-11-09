class StartSendingPeriodicReportsWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    1.minute
  end

  def after_skip
    logger.warn "The job execution is skipped."
  end

  def _timeout_in
    120.minutes
  end

  def retry_in
    1.hour + rand(30.minutes)
  end

  # options:
  def perform(options = {})
    if GlobalDirectMessageLimitation.new.limited?
      logger.warn "Creating a direct message is limited."
      StartSendingPeriodicReportsWorker.perform_in(retry_in, options)
      return
    end

    StartSendingPeriodicReportsTask.new.start!

  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
