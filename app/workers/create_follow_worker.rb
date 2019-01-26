class CreateFollowWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    raised = false
    request = FollowRequest.order(created_at: :asc).where(user_id: user_id).where.not(uid: nil)
    if request
      follow(request.user, request.uid)
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
    CreateFollowWorker.perform_in(interval, user_id) if FollowRequest.exists?(user_id: user_id)
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
