# I want to print this class name to sidekiq.log.
class CreateBatchTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def expire_in
    1.day
  end
end
