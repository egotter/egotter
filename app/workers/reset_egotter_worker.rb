class ResetEgotterWorker
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

    ResetEgotterLog.find_by(request_id: request_id)&.failed!(Timeout::Error, 'Timeout')
    QueueingRequests.new(self.class).delete(request_id)
    RunningQueue.new(self.class).delete(request_id)
    self.class.perform_in(retry_in, request_id, options)
  end

  def retry_in
    1.minute
  end

  def perform(request_id, options = {})
    request = ResetEgotterRequest.find(request_id)
    log = ResetEgotterLog.create(request_id: request_id, message: 'Starting')

    request.perform!(send_dm: true)
    request.finished!

    log.finished!
  rescue ResetEgotterRequest::RecordNotFound => e
    request.finished!
    log.finished!('Record not found')
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id}"
    logger.info e.backtrace.join("\n")

    ResetEgotterLog.find_by(request_id: request_id)&.failed!(e.class, e.message.truncate(100))
  end
end
