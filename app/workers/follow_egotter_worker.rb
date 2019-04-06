class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def after_timeout(*args)
    self.class.perform_in(retry_in, *args)
  end

  def retry_in
    1.hour
  end

  def perform(*args)
    10.times do
      request = FollowRequest.not_finished.order(created_at: :desc).find_by(uid: User::EGOTTER_UID)
      break unless request
      do_perform(request)
    end

    self.class.perform_in(1.minute)
  rescue => e
    self.class.perform_in(retry_in)
  end

  def do_perform(request)
    log = CreateFollowLog.create_by(request: request)
    request.perform!
    request.finished!
    log.update(status: true)
  rescue FollowRequest::Unauthorized,
      FollowRequest::CanNotFollowYourself,
      FollowRequest::NotFound,
      FollowRequest::Suspended,
      FollowRequest::TemporarilyLocked,
      FollowRequest::AlreadyRequestedToFollow,
      FollowRequest::AlreadyFollowing => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))
    request.finished!
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request.inspect}"
    logger.info e.backtrace.join("\n")

    log.update(error_class: e.class, error_message: e.message.truncate(100))

    raise
  end
end
