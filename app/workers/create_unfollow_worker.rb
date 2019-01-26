class CreateUnfollowWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    raised = false
    request = UnfollowRequest.order(created_at: :asc).find_by(user_id: user_id)
    if request
      unfollow(request.user, request.uid)
      request.destroy
    end
  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id)
    logger.warn "#{e.class} #{e.message} #{user_id} #{request.inspect}"
    request.destroy
  rescue Twitter::Error::Forbidden => e
    handle_forbidden_exception(e, user_id: user_id)
    logger.warn "#{e.class} #{e.message} #{user_id} #{request.inspect}"
    raised = true
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{request.inspect}"
    raised = true
  ensure
    interval = raised ? 30.minutes.since : 10.seconds.since
    CreateUnfollowWorker.perform_in(interval, user_id) if UnfollowRequest.exists?(user_id: user_id)
  end

  private

  def unfollow(user, uid)
    client = user.api_client.twitter
    from_uid = user.uid.to_i
    to_uid = uid.to_i
    if from_uid != to_uid && client.friendship?(from_uid, to_uid)
      client.unfollow(to_uid)
    end
  end
end
