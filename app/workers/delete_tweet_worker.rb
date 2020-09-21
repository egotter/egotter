class DeleteTweetWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  # options:
  #   request_id
  def perform(user_id, tweet_id, options = {})
    client = User.find(user_id).api_client.twitter
    destroy_status!(client, tweet_id)
    DeleteTweetsRequest.find(options['request_id']).increment!(:destroy_count) if options['request_id']
  rescue => e
    logger.warn "#{e.inspect} user_id=#{user_id} tweet_id=#{tweet_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  private

  def destroy_status!(client, tweet_id)
    client.destroy_status(tweet_id)
  rescue => e
    if ServiceStatus.retryable_error?(e)
      retry
    elsif TweetStatus.no_status_found?(e)
      # Do nothing
    else
      raise
    end
  end
end
