class CreateFollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'follow', retry: 0, backtrace: false

  # options:
  #   enqueue_location
  def perform(request_id, options = {})
    request = FollowRequest.find(request_id)
    log = CreateFollowLog.create_by(request: request)

    request.perform!
    request.finished!

    log.update(status: true)

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
  rescue FollowRequest::TooManyFollows => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))
    logger.warn "#{e.class} Sleep for 1 hour"
    sleep 1.hour
    CreateFollowWorker.perform_async(request_id, options)
  rescue FollowRequest::Error => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))
    CreateFollowWorker.perform_async(request_id, options)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")

    log.update(error_class: e.class, error_message: e.message.truncate(100))
    CreateFollowWorker.perform_async(request_id, options)
  end
end
