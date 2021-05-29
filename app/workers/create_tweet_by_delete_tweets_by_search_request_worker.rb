class CreateTweetByDeleteTweetsBySearchRequestWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    60.seconds
  end

  # options:
  def perform(request_id, options = {})
    request = DeleteTweetsBySearchRequest.find(request_id)
    request.post_tweet!(false)
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end
