class SendDeleteTweetsFinishedMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    request.finished!
    SlackBotClient.channel('monit_delete_tweets').post_message("`Finished` #{request.to_message}")
  rescue => e
    Airbag.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
  end
end
