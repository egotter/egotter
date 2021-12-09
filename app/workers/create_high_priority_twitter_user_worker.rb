# TODO Remove later
class CreateHighPriorityTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def after_skip(request_id, options = {})
    SkippedCreateHighPriorityTwitterUserWorker.perform_async(request_id, options)
  end

  def after_expire(request_id, options = {})
    ExpiredCreateHighPriorityTwitterUserWorker.perform_async(request_id, options)
  end
end
