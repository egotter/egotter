class ResetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def timeout_in
    10.seconds
  end

  def perform(request_id, options = {})
    log = ResetEgotterLog.find(request_id)
    log.perform(send_dm: true)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id}"
    logger.info e.backtrace.join("\n")
  end
end
