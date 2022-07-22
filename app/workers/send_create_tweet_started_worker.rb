class SendCreateTweetStartedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   via
  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)
    SendMessageToSlackWorker.perform_async(:monit_tweet, "`Started` #{request.to_message(via: options['via'])}")
  rescue => e
    Airbag.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}", backtrace: e.backtrace
  end
end
