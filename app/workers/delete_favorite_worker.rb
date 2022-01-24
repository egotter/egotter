class DeleteFavoriteWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'batch', retry: 0, backtrace: false

  # options:
  #   request_id
  #   last_tweet
  def perform(user_id, tweet_id, options = {})
    request = DeleteFavoritesRequest.find(options['request_id'])
    if request.stopped_at
      Airbag.info "This request is already stopped user_id=#{user_id} tweet_id=#{tweet_id} options=#{options.inspect}"
      return
    end

    client = User.find(user_id).api_client.twitter
    if destroy_favorite!(client, tweet_id, request)
      request.increment!(:destroy_count)
    end


    if options['last_tweet']
      SendDeleteFavoritesFinishedMessageWorker.perform_in(5.seconds, request.id)
    end
  rescue => e
    if TwitterApiStatus.retry_timeout?(e)
      DeleteTweetWorker::RETRY_HANDLER.call(e, self.class, user_id, tweet_id, options)
    else
      handle_worker_error(e, user_id: user_id, tweet_id: tweet_id, options: options)
    end
  end

  private

  def destroy_favorite!(client, tweet_id, request)
    client.unfavorite!(tweet_id)
  rescue => e
    DeleteTweetWorker::ERROR_HANDLER.call(e, request)
  end
end
