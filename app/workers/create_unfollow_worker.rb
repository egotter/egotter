class CreateUnfollowWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    raised = false
    request = fetch_request(user_id)
    if request
      unfollow(request.user, request.uid)
      request.destroy
    end
  rescue => e
    if e.class == Twitter::Error::Unauthorized
      handle_unauthorized_exception(e, user_id: user_id)
    elsif e.class == Twitter::Error::Forbidden
      handle_forbidden_exception(e, user_id: user_id)
      raised = true
    else
      raised = true
    end

    logger.warn "#{e.class} #{e.message} #{user_id} #{request.inspect}"
    request.update(error_class: e.class, error_message: e.message.truncate(150))
  ensure
    interval = raised ? 30.minutes.since : 10.seconds.since
    self.class.perform_in(interval, user_id) if UnfollowRequest.without_error.exists?(user_id: user_id)
  end

  private

  def fetch_request(user_id)
    UnfollowRequest.order(created_at: :asc).
        where(user_id: user_id).
        without_error.first
  end

  def unfollow(user, uid)
    client = user.api_client.twitter
    from_uid = user.uid.to_i
    to_uid = uid.to_i
    if from_uid != to_uid && client.friendship?(from_uid, to_uid)
      client.unfollow(to_uid)
    end
  end
end
