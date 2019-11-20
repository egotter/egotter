class CreateFollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'follow', retry: 0, backtrace: false

  # options:
  #   enqueue_location
  def perform(request_id, options = {})
    request = FollowRequest.find(request_id)
    CreateFollowTask.new(request).start!

  rescue FollowRequest::TooManyRetries,
      FollowRequest::Unauthorized,
      FollowRequest::CanNotFollowYourself,
      FollowRequest::NotFound,
      FollowRequest::Suspended,
      FollowRequest::TemporarilyLocked,
      FollowRequest::AlreadyRequestedToFollow,
      FollowRequest::AlreadyFollowing => e

    request.update(error_class: e.class, error_message: e.message.truncate(100))
    request.finished!

    if e.class == FollowRequest::TooManyRetries
      logger.warn "Stop retrying #{e.class} #{e.message} #{request.inspect} #{request.logs.pluck(:error_class).inspect}"
    end
  rescue FollowRequest::TooManyFollows => e
    logger.warn "#{e.class} Sleep for 1 hour"
    sleep 1.hour
    CreateFollowWorker.perform_async(request_id, options)
  rescue FollowRequest::Error => e
    CreateFollowWorker.perform_async(request_id, options)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")

    CreateFollowWorker.perform_async(request_id, options)
  end

  def fetch_one
    request = FollowRequest.where(finished_at: nil).
        where(uid: User::EGOTTER_UID).
        where(error_class: '').
        order(created_at: :desc).first
    CreateFollowWorker.perform_async(request.id)
  end
end
