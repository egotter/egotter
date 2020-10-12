class CreateTweetWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    TweetRequest.find(request_id).user_id
  end

  def unique_in
    10.minutes
  end

  # options:
  #   requested_by
  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)
    request.finished!
    ConfirmTweetWorker.perform_async(request_id, confirm_count: 0)
  rescue => e
    logger.warn "#{e.inspect} request=#{request.inspect} options=#{options}"
  end
end
