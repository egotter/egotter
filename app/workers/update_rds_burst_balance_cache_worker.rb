class UpdateRdsBurstBalanceCacheWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key
    -1
  end

  def unique_in
    5.minutes
  end

  def expire_in
    1.minute
  end

  # options:
  def perform(options = {})
    RdsBurstBalanceCache.new.update
  rescue => e
    handle_worker_error(e)
  end
end
