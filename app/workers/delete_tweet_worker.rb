class DeleteTweetWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  # options:
  #   request_id
  #   last_tweet
  def perform(user_id, tweet_id, options = {})
    request = DeleteTweetsRequest.find(options['request_id'])
    if request.stopped_at
      Airbag.info "This request is stopped user_id=#{user_id} tweet_id=#{tweet_id} options=#{options.inspect}"
      return
    end

    client = User.find(user_id).api_client.twitter
    if destroy_status!(client, tweet_id, request)
      request.increment!(:destroy_count)
    end

    if options['last_tweet']
      SendDeleteTweetsFinishedMessageWorker.perform_in(5.seconds, request.id)
    end
  rescue => e
    if TwitterApiStatus.retry_timeout?(e)
      if options['retries']
        Airbag.warn { "#{e.inspect} user_id=#{user_id} tweet_id=#{tweet_id} options=#{options}" }
      else
        options['retries'] = 1
        Airbag.warn { "RETRY: #{e.inspect} user_id=#{user_id} tweet_id=#{tweet_id} options=#{options}" } # TODO Remove
        DeleteTweetWorker.perform_in(rand(10) + 10, user_id, tweet_id, options)
      end
    else
      handle_worker_error(e, user_id: user_id, tweet_id: tweet_id, options: options)
    end
  end

  private

  def destroy_status!(client, tweet_id, request)
    client.destroy_status(tweet_id)
  rescue => e
    request.update(error_message: e.inspect)

    if TweetStatus.no_status_found?(e) ||
        TweetStatus.not_authorized?(e) ||
        TweetStatus.that_page_does_not_exist?(e) ||
        TweetStatus.forbidden?(e)
      nil
    elsif TwitterApiStatus.your_account_suspended?(e) ||
        TwitterApiStatus.invalid_or_expired_token?(e) ||
        TwitterApiStatus.suspended?(e) ||
        TweetStatus.temporarily_locked?(e)
      request.update(stopped_at: Time.zone.now)
      Airbag.warn { "Request stopped request=#{request.inspect}" }
      nil
    else
      raise
    end
  end
end
