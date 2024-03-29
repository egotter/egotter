class ResetEgotterWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    1.minute
  end

  def after_skip(request_id, options = {})
    Airbag.warn "Skipped #{request_id}"
  end

  def timeout_in
    1.minute
  end

  def retry_in
    unique_in + rand(120)
  end

  # options:
  def perform(request_id, options = {})
    request = ResetEgotterRequest.find(request_id)
    task = ResetEgotterTask.new(request)
    task.start!
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end
