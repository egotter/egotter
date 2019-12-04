class CreateUnfollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'unfollow', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  # options:
  #   enqueue_location
  def perform(request_id, options = {})
    request = UnfollowRequest.find(request_id)
    CreateUnfollowTask.new(request).start!

  rescue UnfollowRequest::TooManyUnfollows => e
    logger.warn "#{e.class} Sleep for 1 hour"
    sleep 1.hour
    CreateUnfollowWorker.perform_async(request_id, options)

  rescue UnfollowRequest::RetryableError => e
    CreateUnfollowWorker.perform_async(request_id, options)

  rescue UnfollowRequest::Error => e
    logger.warn e.inspect

  rescue => e
    logger.warn "Don't retry. #{e.class} #{e.message} #{request_id} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    logger.info e.backtrace.join("\n")
  end
end
