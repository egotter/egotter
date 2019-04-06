class CreateFollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(request_id, options = {})
    request = FollowRequest.find(request_id)
    log = CreateFollowLog.create_by(request: request)

    request.perform!
    request.finished!

    log.update(status: true)

    enqueue_next_request(request)

  rescue FollowRequest::TooManyRetries,
      FollowRequest::Unauthorized,
      FollowRequest::CanNotFollowYourself,
      FollowRequest::NotFound,
      FollowRequest::Suspended,
      FollowRequest::TemporarilyLocked,
      FollowRequest::AlreadyRequestedToFollow,
      FollowRequest::AlreadyFollowing => e

    log.update(error_class: e.class, error_message: e.message.truncate(100))
    request.update(error_class: e.class, error_message: e.message.truncate(100))
    request.finished!

    if e.class == FollowRequest::TooManyRetries
      logger.warn "Stop retrying #{e.class} #{e.message} #{request.inspect} #{request.logs.pluck(:error_class).inspect}"
    end

    enqueue_next_request(request)
  rescue FollowRequest::Error => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))

    enqueue_next_request(request)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")

    log.update(error_class: e.class, error_message: e.message.truncate(100))

    enqueue_next_request(request)
  end

  private

  def enqueue_next_request(request)
    next_request = FollowRequest.not_finished.order(created_at: :desc).find_by(user_id: request.user_id)
    return unless next_request

    self.class.perform_in(next_request.perform_interval, next_request.id, enqueue_location: 'in worker')
  end
end
