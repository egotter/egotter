class SendDeleteTweetsFinishedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    SendMessageToSlackWorker.perform_async(:delete_tweets, "`Finished` #{request.to_message}")
  rescue => e
    Airbag.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end
end
