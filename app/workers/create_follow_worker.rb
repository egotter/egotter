class CreateFollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'follow', retry: 0, backtrace: false

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
    if GlobalFollowLimitation.new.limited?
      CreateFollowWorker.perform_in(retry_in, request_id, options)
    else
      request = FollowRequest.find(request_id)
      CreateFollowTask.new(request).start!
    end

  rescue FollowRequest::AlreadyFollowing,
      FollowRequest::AlreadyRequestedToFollow,
      FollowRequest::NotFound,
      FollowRequest::Suspended,
      FollowRequest::Blocked,
      FollowRequest::Unauthorized,
      FollowRequest::CanNotFollowYourself,
      FollowRequest::TemporarilyLocked => e
    Airbag.info "Skip #{e.inspect}"
  rescue FollowRequest::TooManyFollows, FollowRequest::ServiceUnavailable => e
    Airbag.warn "Retry later #{e.class}"
    CreateFollowWorker.perform_in(retry_in, request_id, options)

  rescue FollowRequest::RetryableError => e
    CreateFollowWorker.perform_async(request_id, options)

  rescue FollowRequest::Error => e
    Airbag.warn "Don't care. #{e.inspect} request_id=#{request_id} options=#{options.inspect}"

  rescue => e
    Airbag.warn "Don't retry. #{e.class} #{e.message} request_id=#{request_id} options=#{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    Airbag.info e.backtrace.join("\n")
  end
end
