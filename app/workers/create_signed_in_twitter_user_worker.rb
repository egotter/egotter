# I want to print this class name to sidekiq.log.
class CreateSignedInTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def after_skip(request_id, options = {})
    SkippedCreateSignedInTwitterUserWorker.perform_async(request_id, options)
  end

  def after_expire(request_id, options = {})
    ExpiredCreateSignedInTwitterUserWorker.perform_async(request_id, options)
  end
end
