class CreateUnfollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'unfollow', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    10.minutes
  end

  def retry_in
    1.hour + rand(30.minutes)
  end

  # options:
  #   enqueue_location
  def perform(request_id, options = {})
    if GlobalUnfollowLimitation.new.limited?
      CreateUnfollowWorker.perform_in(retry_in, request_id, options)
    else
      request = UnfollowRequest.find(request_id)
      CreateUnfollowTask.new(request).start!
    end

  rescue UnfollowRequest::NotFollowing,
      UnfollowRequest::Unauthorized,
      UnfollowRequest::NotFound,
      UnfollowRequest::Suspended,
      UnfollowRequest::CanNotUnfollowYourself => e
    logger.info "Skip #{e.inspect}"
  rescue UnfollowRequest::TooManyUnfollows => e
    # This exception is never raised
    logger.warn "#{e.class} Retry later"
    CreateUnfollowWorker.perform_in(retry_in, request_id, options)

  rescue UnfollowRequest::RetryableError => e
    CreateUnfollowWorker.perform_async(request_id, options)

  rescue UnfollowRequest::Error => e
    logger.warn "Don't care. #{e.inspect}"

  rescue => e
    logger.warn "Don't retry. #{e.class} #{e.message} #{request_id} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    logger.info e.backtrace.join("\n")
  end
end
