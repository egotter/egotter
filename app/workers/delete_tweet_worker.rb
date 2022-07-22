class DeleteTweetWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'batch', retry: 0, backtrace: false

  # options:
  #   request_id
  #   last_tweet
  def perform(user_id, tweet_id, options = {})
    request = DeleteTweetsRequest.find(options['request_id'])
    return if request.stopped?

    client = User.find(user_id).api_client.twitter

    if destroy_status!(client, tweet_id, request)
      request.increment!(:destroy_count)
    end

    if request.last_tweet == tweet_id || options['last_tweet']
      SendDeleteTweetsFinishedMessageWorker.perform_in(5.seconds, request.id)
    end
  rescue => e
    if TwitterApiStatus.retry_timeout?(e)
      RETRY_HANDLER.call(e, self.class, user_id, tweet_id, options)
    else
      handle_worker_error(e, user_id: user_id, tweet_id: tweet_id, options: options)
    end
  end

  private

  def destroy_status!(client, tweet_id, request)
    client.destroy_status(tweet_id)
  rescue => e
    ERROR_HANDLER.call(e, request)
  end

  RETRY_HANDLER = Proc.new do |e, worker_class, user_id, tweet_id, options|
    if options['retries']
      Airbag.warn "Retry exhausted exception=#{e.inspect} user_id=#{user_id} tweet_id=#{tweet_id} options=#{options}", backtrace: e.backtrace
    else
      options['retries'] = 1
      worker_class.perform_in(rand(10) + 10, user_id, tweet_id, options)
    end
  end

  ERROR_HANDLER = Proc.new do |e, request|
    request.update(error_class: e.class, error_message: e.message)
    request.increment!(:errors_count)

    if TweetStatus.no_status_found?(e) ||
        TweetStatus.not_authorized?(e) ||
        TweetStatus.that_page_does_not_exist?(e) ||
        TweetStatus.forbidden?(e)
      # Do nothing
    elsif TwitterApiStatus.your_account_suspended?(e) ||
        TwitterApiStatus.invalid_or_expired_token?(e) ||
        TwitterApiStatus.suspended?(e) ||
        TweetStatus.temporarily_locked?(e) ||
        TwitterApiStatus.might_be_automated?(e)
      request.update(stopped_at: Time.zone.now)
    elsif request.respond_to?(:too_many_errors?) && request.too_many_errors?
      request.update(stopped_at: Time.zone.now)
    else
      raise e
    end
  end
end
