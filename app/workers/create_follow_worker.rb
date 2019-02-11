class CreateFollowWorker
  include Sidekiq::Worker
  include Concerns::FollowAndUnfollowWorker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, options = {})
    do_perform(self.class, FollowRequest, user_id, options)
  end
end
