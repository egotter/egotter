class ResetCacheWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def timeout_in
    30.seconds
  end

  def after_timeout(request_id, options = {})
    Airbag.warn "Timeout #{timeout_in} #{request_id}"
  end

  def perform(request_id, options = {})
    request = ResetCacheRequest.find(request_id)
    request.perform!
    request.finished!
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end
