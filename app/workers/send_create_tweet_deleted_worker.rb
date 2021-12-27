class SendCreateTweetDeletedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)
    SendMessageToSlackWorker.perform_async(:monit_tweet, "`Deleted` #{request.to_message}")
  rescue => e
    Airbag.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end
end
