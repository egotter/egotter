# TODO Remove later
class CreateHighPriorityTwitterDBUserWorker < CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def after_skip(uids, options = {})
    SkippedHighPriorityCreateTwitterDBUserWorker.perform_async(uids, options)
  end
end
