class DeleteTweetByArchiveWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  # options:
  def perform(request_id, tweet_id, options = {})
    request = DeleteTweetsByArchiveRequest.find(request_id)
    user = request.user

    client = user.api_client.twitter
    DeleteTweetWorker.new.send(:destroy_status!, client, tweet_id)

    request.increment!(:deletions_count)
  rescue => e
    handle_worker_error(e, request_id: request_id, tweet_id: tweet_id, options: options)
  end
end
