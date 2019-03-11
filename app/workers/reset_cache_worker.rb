class ResetCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def after_skip(request_id, options = {})
    logger.warn "Skipped #{request_id}"
  end

  def timeout_in
    10.seconds
  end

  def after_timeout(request_id, options = {})
    logger.warn "Timeout #{timeout_in} #{request_id}"
  end

  def request_class
    ResetCacheRequest
  end

  def log_class
    ResetCacheLog
  end

  def perform(request_id, options = {})
    request = request_class.find(request_id)
    log = log_class.create(request_id: request_id, message: 'Starting')

    request.perform!
    request.finished!

    log.finished!
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id}"
    logger.info e.backtrace.join("\n")

    log_class.find_by(request_id: request_id)&.failed!(e.class, e.message.truncate(100))
  end
end
