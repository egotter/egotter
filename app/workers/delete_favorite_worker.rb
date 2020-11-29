class DeleteFavoriteWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  # options:
  #   request_id
  #   last_tweet
  def perform(user_id, tweet_id, options = {})
    client = User.find(user_id).api_client.twitter
    result = destroy_favorite!(client, tweet_id)

    if result && options['request_id']
      DeleteFavoritesRequest.find(options['request_id']).increment!(:destroy_count)
    end

    if options['request_id'] && options['last_tweet']
      DeleteFavoritesWorker.perform_async(options['request_id'])
    end
  rescue => e
    set_error_to_request(e, options['request_id']) if options['request_id']
    handle_worker_error(e, user_id: user_id, tweet_id: tweet_id, options: options)
  end

  private

  def destroy_favorite!(client, tweet_id)
    retries ||= 3
    client.unfavorite!(tweet_id)
  rescue => e
    if ServiceStatus.retryable_error?(e)
      if (retries -= 1) > 0
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    elsif TwitterApiStatus.invalid_or_expired_token?(e) ||
        TwitterApiStatus.suspended?(e) ||
        TweetStatus.no_status_found?(e) ||
        TweetStatus.not_authorized?(e) ||
        TweetStatus.that_page_does_not_exist?(e)
      nil
    else
      raise
    end
  end

  def set_error_to_request(e, request_id)
    DeleteFavoritesRequest.find(request_id).update(error_class: e.class, error_message: e.message)
  end

  class RetryExhausted < StandardError; end
end
