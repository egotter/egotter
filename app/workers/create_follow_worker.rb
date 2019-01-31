class CreateFollowWorker
  include Sidekiq::Worker
  include Concerns::FollowAndUnfollowWorker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    do_perform(self.class, FollowRequest, user_id) do |request|
      follow(request.user.api_client.twitter, request.user.uid, request.uid)
    end
  end

  def follow(client, from_uid, to_uid)
    from_uid = from_uid.to_i
    to_uid = to_uid.to_i

    raise CanNotFollowYourself if from_uid == to_uid
    raise HaveAlreadyFollowed if client.friendship?(from_uid, to_uid)

    client.follow!(to_uid)
  end
end
