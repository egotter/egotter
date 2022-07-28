class DeleteFavoriteWorker
  include Sidekiq::Worker
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
      if options['retries']
        Airbag.warn 'Retry exhausted', exception: e.inspect, user_id: user_id, tweet_id: tweet_id, options: options
      else
        self.class.perform_in(rand(10) + 10, user_id, tweet_id, options.merge('retries' => 1))
      end
    else
      Airbag.exception e, user_id: user_id, tweet_id: tweet_id, options: options
    end
  end

  private

  def destroy_favorite!(client, tweet_id, request)
    client.unfavorite!(tweet_id)
  rescue => e
    request.update(error_class: e.class, error_message: e.message)
    request.increment!(:errors_count)

    if request.too_many_errors?
      request.update(stopped_at: Time.zone.now)
    end

    handler = DeleteTweetWorker::ErrorHandler.new(e)

    if handler.stop?
      request.update(stopped_at: Time.zone.now)
    elsif handler.raise?
      raise
    end
  end
end
