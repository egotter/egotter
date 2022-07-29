class DeleteTweetBySearchWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'batch', retry: 0, backtrace: false

  # options:
  def perform(request_id, tweet_id, options = {})
    request = DeleteTweetsBySearchRequest.find(request_id)
    return if request.stopped_at

    user = request.user

    unless (record = DeletableTweet.deletion_reserved.not_deleted.find_by(uid: user.uid, tweet_id: tweet_id))
      request.update(error_message: "DeletableTweet not found request_id=#{request_id} tweet_id=#{tweet_id}")
      return
    end

    destroy_status(record, request)

    if request.last_tweet_id?(tweet_id)
      SendDeleteTweetsBySearchFinishedMessageWorker.perform_in(5.seconds, request.id)
    end
  rescue => e
    Airbag.exception e, request_id: request_id, tweet_id: tweet_id, options: options
  end

  private

  def destroy_status(tweet, request)
    tweet.delete_tweet!
    request.increment!(:deletions_count)
  rescue => e
    request.update(error_message: e.inspect)
    request.increment!(:errors_count)

    handler = DeleteTweetWorker::ErrorHandler.new(e)

    if handler.stop?
      request.update(stopped_at: Time.zone.now)
    elsif handler.raise?
      raise
    end
  end
end
