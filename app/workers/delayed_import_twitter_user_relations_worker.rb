class DelayedImportTwitterUserRelationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    # Do nothing.
  end

  class << self
    def twitter_user_ids
      name = DelayedImportTwitterUserRelationsWorker.to_s
      jobs = Sidekiq::Queue.new(name).select {|job| job.klass == name}
      jobs.map {|job| job.args.extract_options!['twitter_user_id']}
    end
  end
end
