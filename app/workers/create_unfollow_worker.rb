class CreateUnfollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'unfollow', retry: 0, backtrace: false

  # options:
  #   enqueue_location
  def perform(request_id, options = {})
    request = UnfollowRequest.find(request_id)
    log = CreateUnfollowLog.create_by(request: request)

    request.perform!
    request.finished!

    log.update(status: true)

  rescue UnfollowRequest::TooManyRetries,
      UnfollowRequest::Unauthorized,
      UnfollowRequest::CanNotUnfollowYourself,
      UnfollowRequest::NotFound,
      UnfollowRequest::NotFollowing => e

    log.update(error_class: e.class, error_message: e.message.truncate(100))
    request.update(error_class: e.class, error_message: e.message.truncate(100))
    request.finished!

    if e.class == UnfollowRequest::TooManyRetries
      logger.warn "Stop retrying #{e.class} #{e.message} #{request.inspect} #{request.logs.pluck(:error_class).inspect}"
    end
  rescue UnfollowRequest::Error => e
    log.update(error_class: e.class, error_message: e.message.truncate(100))
    CreateUnfollowWorker.perform_async(request_id, options)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")

    log.update(error_class: e.class, error_message: e.message.truncate(100))
    CreateUnfollowWorker.perform_async(request_id, options)
  end
end
