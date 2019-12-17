class ResetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    1.minute
  end

  def after_skip(request_id, options = {})
    logger.warn "Skipped #{request_id}"
  end

  def timeout_in
    1.minute
  end

  def after_timeout(request_id, options = {})
    logger.warn "Timeout #{timeout_in} #{request_id}"
    ResetEgotterLog.find_by(request_id: request_id)&.failed!(Timeout::Error, 'Timeout')
    ResetEgotterWorker.perform_in(retry_in, request_id, options)
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
    logger.warn "#{e.inspect} #{request_id} #{"Caused by #{e.cause.inspect}" if e.cause}"
    logger.info e.backtrace.join("\n")
  end
end
