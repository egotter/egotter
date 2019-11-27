class ResetCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def after_skip(request_id, options = {})
    ResetCacheLog.find_or_initialize_by(request_id: request_id)&.failed!('Skipped', '')
  end

  def timeout_in
    30.seconds
  end

  def after_timeout(request_id, options = {})
    logger.warn "Timeout #{timeout_in} #{request_id}"
    ResetCacheLog.find_or_create_by(request_id: request_id)&.failed!('Timeout', '')
  end

  def perform(request_id, options = {})
    request = ResetCacheRequest.find(request_id)
    log = ResetCacheLog.create(request_id: request_id, user_id: request.user.id, message: 'Starting')

    request.perform!
    request.finished!

    log.finished!
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id}"
    logger.info e.backtrace.join("\n")

    ResetCacheLog.find_or_create_by(request_id: request_id)&.failed!(e.class, e.message.truncate(100))
  end
end
