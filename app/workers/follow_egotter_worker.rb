class FollowEgotterWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    raised = false
    request = FollowRequest.find_by(id: FollowRequest.pluck(:id).sample)
    if request
      follow(request.user)
      request.destroy
    end
  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: request.user.id)
    request.destroy
  rescue Twitter::Error::Forbidden => e
    handle_forbidden_exception(e, user_id: request.user.id)

    if e.message == FORBIDDEN_MESSAGES[2]
      logger.warn "Unable to follow #{request.inspect}"
    end
    raised = true
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request.inspect}"
    raised = true
  ensure
    interval = raised ? 30.minutes.since : 1.minutes.since
    FollowEgotterWorker.perform_in(interval)
  end

  private

  def follow(user)
    client = user.api_client.twitter
    if user.uid.to_i != User::EGOTTER_UID && !client.friendship?(user.uid.to_i, User::EGOTTER_UID)
      client.follow!(User::EGOTTER_UID)
    end
  end
end
