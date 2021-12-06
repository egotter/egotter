class ConfirmTweetWorker
  include Sidekiq::Worker
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
      Airbag.info e.inspect
      request.update(deleted_at: Time.zone.now)
      SendCreateTweetDeletedWorker.perform_async(request.id)
    end
  end

  def confirm_in(count)
    count < 20 ? 1.seconds : 10.seconds
  end
end
