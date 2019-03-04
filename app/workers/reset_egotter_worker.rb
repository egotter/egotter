class ResetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(request_id, options = {})
    queue = RunningQueue.new(self.class)
    return if !options['skip_queue'] && queue.exists?(request_id)
    queue.add(request_id)

    Timeout.timeout(10) do
      do_perform(request_id)
    end
  rescue Timeout::Error => e
    logger.warn "#{e.class}: #{e.message} #{request_id}"
    logger.info e.backtrace.join("\n")
  end

  def do_perform(request_id)
    log = ResetEgotterLog.find(request_id)
    log.perform(send_dm: true)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id}"
    logger.info e.backtrace.join("\n")
  end
end
