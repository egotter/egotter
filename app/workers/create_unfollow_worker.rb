class CreateUnfollowWorker
  include Sidekiq::Worker
  include Concerns::FollowAndUnfollowWorker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(user_id, options = {})
    do_perform(self.class, UnfollowRequest, user_id, options)
  end
end
