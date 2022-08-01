class SendDeleteTweetsFinishedMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    request.tweet_finished_message if request.tweet
    request.send_finished_message if request.send_dm || request.destroy_count == 0 || request.reservations_count == 0
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end
end
