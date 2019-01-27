class FollowEgotterWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(*args)
    raised = false
    request = fetch_request
    if request
      follow(request.user)
      request.destroy
    end
  rescue => e
    if e.class == Twitter::Error::Unauthorized
      handle_unauthorized_exception(e, user_id: request.user.id)
    elsif e.class == Twitter::Error::Forbidden
      handle_forbidden_exception(e, user_id: request.user.id)
      raised = true
    else
      raised = true
    end

    logger.warn "#{e.class} #{e.message} #{request.inspect}"
    request.update(error_class: e.class, error_message: e.message.truncate(150))
  ensure
    interval = raised ? 30.minutes.since : 1.minutes.since
    self.class.perform_in(interval)
  end

  private

  def fetch_request
    FollowRequest.order(created_at: :desc).
        where(uid: User::EGOTTER_UID).
        without_error.first
  end

  def follow(user)
    client = user.api_client.twitter
    if user.uid.to_i != User::EGOTTER_UID && !client.friendship?(user.uid.to_i, User::EGOTTER_UID)
      client.follow!(User::EGOTTER_UID)
    end
  end
end
