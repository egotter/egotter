class DeleteTweetWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  # options:
  #   request_id
  #   last_tweet
  def perform(user_id, tweet_id, options = {})
    client = User.find(user_id).api_client.twitter
    destroy_status!(client, tweet_id)

    if options['request_id']
      DeleteTweetsRequest.find(options['request_id']).increment!(:destroy_count)
    end

    if options['request_id'] && options['last_tweet']
      DeleteTweetsWorker.perform_async(options['request_id'])
    end
  rescue => e
    logger.warn "#{e.inspect} user_id=#{user_id} tweet_id=#{tweet_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")

    if options['request_id']
      DeleteTweetsRequest.find(options['request_id']).update(error_class: e.class, error_message: e.message)
    end
  end

  private

  def destroy_status!(client, tweet_id)
    client.destroy_status(tweet_id)
  rescue => e
    if ServiceStatus.retryable_error?(e)
      retry
    elsif AccountStatus.invalid_or_expired_token?(e) ||
        TweetStatus.no_status_found?(e) ||
        TweetStatus.not_authorized?(e) ||
        TweetStatus.that_page_does_not_exist?(e)
      # Do nothing
    else
      raise
    end
  end
end
