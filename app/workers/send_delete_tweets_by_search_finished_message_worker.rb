class SendDeleteTweetsBySearchFinishedMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    request = DeleteTweetsBySearchRequest.find(request_id)
    request.finished!
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end
end
