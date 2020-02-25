# Create separated worker class to avoid to skip enqueueing
class SkippedCreatePromptReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    raise 'This job is not executed.'
  end
end
