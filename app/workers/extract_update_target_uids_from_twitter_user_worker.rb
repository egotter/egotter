# TODO Remove later
class ExtractUpdateTargetUidsFromTwitterUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(twitter_user_id, options = {})
    ExtractMissingUidsFromTwitterUserWorker.new.perform(twitter_user_id, options)
  end
end
