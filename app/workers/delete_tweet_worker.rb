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
      Airbag.info "This request is already stopped user_id=#{user_id} tweet_id=#{tweet_id} options=#{options.inspect}"
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
      Airbag.warn { "#{e.inspect} user_id=#{user_id} tweet_id=#{tweet_id} options=#{options}" }
    else
      options['retries'] = 1
      Airbag.warn { "RETRY: #{e.inspect} user_id=#{user_id} tweet_id=#{tweet_id} options=#{options}" } # TODO Remove
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
      nil
    elsif TwitterApiStatus.your_account_suspended?(e) ||
        TwitterApiStatus.invalid_or_expired_token?(e) ||
        TwitterApiStatus.suspended?(e) ||
        TweetStatus.temporarily_locked?(e)
      request.update(stopped_at: Time.zone.now)
      Airbag.info { "Request stopped request_id=#{request.id} user_id=#{request.user_id}" }
      nil
    else
      raise e
    end
  end
end
