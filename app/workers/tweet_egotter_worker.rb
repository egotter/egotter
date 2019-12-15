class TweetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  # options:
  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)
    tweet = request.perform!
    request.finished!
    send_message_to_slack(request, tweet)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request.inspect} #{options}"
    logger.info e.backtrace.join("\n")
  end

  def send_message_to_slack(request, tweet)
    tweet_url = "https://twitter.com/#{request.user.screen_name}/status/#{tweet[:id]}"
    SlackClient.tweet.send_message("`#{request.id}` `#{request.user_id}` `#{request.text}` #{tweet_url}")
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
  end
end
