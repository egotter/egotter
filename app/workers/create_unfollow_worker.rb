class CreateUnfollowWorker
  include Sidekiq::Worker
  include Concerns::FollowAndUnfollowWorker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, options = {})
    do_perform(self.class, UnfollowRequest, user_id, options) do |request|
      unfollow(request.user.api_client.twitter, request.user.uid, request.uid)
    end
  end

  def unfollow(client, from_uid, to_uid)
    from_uid = from_uid.to_i
    to_uid = to_uid.to_i

    raise CanNotUnfollowYourself if from_uid == to_uid
    raise HaveNotFollowed unless client.friendship?(from_uid, to_uid)

    client.unfollow(to_uid)
  end
end
