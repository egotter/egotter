class SleepWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'sleep', retry: 0, backtrace: false

  def perform(seconds = 30)
    sleep seconds
  end
end
