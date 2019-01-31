class CreateFollowWorker
  include Sidekiq::Worker
  include Concerns::FollowAndUnfollowWorker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    do_perform(self.class, FollowRequest, user_id) do |request|
      follow(request.user, request.uid)
    end
  end

  private

  def follow(user, uid)
    client = user.api_client.twitter
    from_uid = user.uid.to_i
    to_uid = uid.to_i
    if from_uid != to_uid && !client.friendship?(from_uid, to_uid)
      client.follow!(to_uid)
    end
  end
end
