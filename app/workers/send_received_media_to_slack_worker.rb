class SendReceivedMediaToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(response, options = {})
    res = JSON.parse(response, symbolize_names: true)
    dm = DirectMessage.from_response(res)

    if dm.media_url
      client = User.egotter.api_client.twitter
      media = dm.retrieve_media(client)
      SlackBotClient.channel('general').upload_media(media)
    end
  rescue => e
    logger.warn "#{e.inspect} response=#{response.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end
end
