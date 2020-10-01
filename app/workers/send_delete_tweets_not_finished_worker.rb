class SendDeleteTweetsNotFinishedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    unless request.finished?
      SendMessageToSlackWorker.perform_async(:delete_tweets, "request=#{request.inspect}", 'Not finished')
    end
  rescue => e
    logger.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
