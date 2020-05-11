class SkippedCreateSignedInTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    raise 'Do nothing'
  end
end
