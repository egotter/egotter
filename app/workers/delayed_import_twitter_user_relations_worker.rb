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

    def consume_delayed_twitter_user_id(id)
      user = TwitterUser.find(id)
      uids = user.friend_uids + user.follower_uids
      CreateTwitterDBUserWorker.new.perform(uids) if uids.any?
    end
  end
end
