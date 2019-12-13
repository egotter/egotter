class CreateFollowWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'follow', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    10.minutes
  end

  # options:
  #   enqueue_location
  def perform(request_id, options = {})
    request = FollowRequest.find(request_id)
    CreateFollowTask.new(request).start!

  rescue FollowRequest::TooManyFollows => e
    logger.warn "#{e.class} Sleep for 1 hour"
    1.hour.times { sleep 1 }
    CreateFollowWorker.perform_async(request_id, options)

  rescue FollowRequest::RetryableError => e
    CreateFollowWorker.perform_async(request_id, options)

  rescue FollowRequest::Error => e
    logger.warn "Don't care. #{e.inspect}"

  rescue => e
    logger.warn "Don't retry. #{e.class} #{e.message} #{request_id} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    logger.info e.backtrace.join("\n")
  end

  def self.fetch_one
    if Sidekiq::Queue.new('follow').size == 0
      request = FollowRequest.requests_for_egotter.order(created_at: :desc).first
      CreateFollowWorker.perform_async(request.id) if request
    end
  end
end
