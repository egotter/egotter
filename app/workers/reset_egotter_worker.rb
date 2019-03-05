class ResetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def timeout_in
    10.seconds
  end

  def after_timeout(request_id, options = {})
    ResetEgotterLog.create(request_id: request_id, error_class: Timeout::Error, error_message: 'Timeout')
    QueueingRequests.new(self.class).delete(request_id)
    RunningQueue.new(self.class).delete(request_id)
    self.class.perform_in(retry_in, request_id, options)
  end

  def retry_in
    1.minute
  end

  def perform(request_id, options = {})
    request = ResetEgotterRequest.find(request_id)
    request.perform!(send_dm: true)
    request.finished!
  rescue ResetEgotterRequest::RecordNotFound => e
    request.finished!
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id}"
    logger.info e.backtrace.join("\n")

    ResetEgotterLog.create(request_id: request_id, error_class: e.class, error_message: e.message.truncate(100))
  end
end
