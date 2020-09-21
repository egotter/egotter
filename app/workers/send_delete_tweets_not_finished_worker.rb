class SendDeleteTweetsNotFinishedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    unless request.finished?
      SlackClient.delete_tweets.send_message("Not finished request_id=#{request_id} user_id=#{request.user_id} log=#{request.logs.last&.inspect}")
    end
  rescue => e
    logger.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
