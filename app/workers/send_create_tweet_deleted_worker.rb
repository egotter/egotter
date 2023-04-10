class SendCreateTweetDeletedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: SendCreateTweetDeletedWorker is stopped', request_id: request_id
      return
    end

    request = TweetRequest.find(request_id)
    SendMessageToSlackWorker.perform_async(:monit_tweet, "`Deleted` #{request.to_message}")
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end
end
