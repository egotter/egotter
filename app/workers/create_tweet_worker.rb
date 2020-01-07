class CreateTweetWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  # options:
  #   requested_by
  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)
    tweet = request.perform!
    request.finished!
    ConfirmTweetWorker.perform_async(request_id, confirm_count: 0)
    send_message_to_slack(request, tweet, options)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request.inspect} #{options}"
    notify_airbrake(e)
  end

  def tweet_url(screen_name, tweet_id)
    "https://twitter.com/#{screen_name}/status/#{tweet_id}"
  end

  def send_message_to_slack(request, tweet, options)
    user = request.user
    params = {
        request_id: request.id,
        user_id: user.id,
        search_count: {
            max: SearchCountLimitation.max_count(user),
            remaining: SearchCountLimitation.remaining_count(user: user),
            current: SearchCountLimitation.current_count(user: user),
            sharing_bonus: SearchCountLimitation.current_sharing_bonus(user),
        },
        sharing_count: user.sharing_count,
        text: request.text + ' ',
        requested_by: options['requested_by'],
    }
    SlackClient.tweet.send_message(params.inspect + ' ' + tweet_url(user.screen_name, tweet.id))
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
    notify_airbrake(e)
  end
end
