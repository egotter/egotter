class SendDeleteTweetsNotFinishedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    if !request.stopped_at && !request.finished_at
      SendMessageToSlackWorker.perform_async(:monit_delete_tweets, "`Not finished` #{request.to_message}")
    end
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end
end
