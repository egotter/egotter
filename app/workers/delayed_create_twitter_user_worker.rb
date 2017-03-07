class DelayedCreateTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  private

  def before_perform(*args)
    true
  end
end
