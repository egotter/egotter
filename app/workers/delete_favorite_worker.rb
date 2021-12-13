class DeleteFavoriteWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  # options:
  #   request_id
  #   last_tweet
  def perform(user_id, tweet_id, options = {})
    request = DeleteFavoritesRequest.find(options['request_id'])
    if request.stopped_at
      Airbag.info "This request is stopped user_id=#{user_id} tweet_id=#{tweet_id} options=#{options.inspect}"
      return
    end

    client = User.find(user_id).api_client.twitter
    destroy_favorite!(client, tweet_id)

    request.increment!(:destroy_count)

    if options['last_tweet']
      request.finished!
      SendDeleteFavoritesFinishedWorker.perform_async(request.id)
    end
  rescue => e
    if TwitterApiStatus.your_account_suspended?(e)
      request.update(stopped_at: Time.zone.now)
      Airbag.warn "Stop request user_id=#{user_id} tweet_id=#{tweet_id} request=#{request.inspect}"
    end
    request.update(error_message: e.inspect)
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

  class RetryExhausted < StandardError; end
end
