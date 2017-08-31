class FollowEgotterWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    if user_id
      follow(User.find(user_id))
    else
      request = FollowRequest.find_by(id: FollowRequest.pluck(:id).sample)
      if request
        follow(request.user)
        request.destroy
      end
    end
  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id)
  rescue Twitter::Error::Forbidden => e
    handle_forbidden_exception(e, user_id: user_id)

    if e.message == FORBIDDEN_MESSAGES[2] # You are unable to follow more people ...
      FollowRequest.create(user_id: user_id)
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id}"
  ensure
    FollowEgotterWorker.perform_in(1.minute.since, nil) unless user_id
  end

  private

  def follow(user)
    client = user.api_client.twitter
    if user.uid.to_i != User::EGOTTER_UID && !client.friendship?(user.uid.to_i, User::EGOTTER_UID)
      client.follow!(User::EGOTTER_UID)
    end
  end
end
