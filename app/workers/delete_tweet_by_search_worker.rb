class DeleteTweetBySearchWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'batch', retry: 0, backtrace: false

  # options:
  def perform(request_id, tweet_id, options = {})
    request = DeleteTweetsBySearchRequest.find(request_id)
    user = request.user

    unless (record = DeletableTweet.deletion_reserved.not_deleted.find_by(uid: user.uid, tweet_id: tweet_id))
      request.update(error_message: "DeletableTweet not found request_id=#{request_id} tweet_id=#{tweet_id}")
      return
    end

    record.delete_tweet!
    request.increment!(:deletions_count)

    if request.last_tweet_id?(tweet_id)
      SendDeleteTweetsBySearchFinishedMessageWorker.perform_in(5.seconds, request.id)
    end
  rescue => e
    request.update(error_message: e.inspect)
    Airbag.exception e, request_id: request_id, tweet_id: tweet_id, options: options
  end
end
