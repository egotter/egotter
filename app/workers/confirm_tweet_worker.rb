class ConfirmTweetWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    "#{request_id}-#{options['confirm_count']}"
  end

  # options:
  #   confirm_count
  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)

    begin
      request.user.api_client.twitter.status(request.tweet_id)
      if (options['confirm_count'] += 1) < 60
        ConfirmTweetWorker.perform_in(confirm_in(options['confirm_count']), request_id, options)
      end
    rescue => e
      logger.info e.inspect
      request.update(deleted_at: Time.zone.now)
      send_message_to_slack(request)
    end
  end

  def confirm_in(count)
    count < 10 ? 2.seconds : 10.seconds
  end

  def send_message_to_slack(request)
    params = {
        user_id: request.user_id,
        request_id: request.id,
        deleted_at: request.deleted_at
    }
    SlackClient.tweet.send_message(params.inspect)
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
    notify_airbrake(e)
  end
end
