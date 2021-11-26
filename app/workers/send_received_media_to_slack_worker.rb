class SendReceivedMediaToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(response, options = {})
    res = JSON.parse(response, symbolize_names: true)
    dm = DirectMessageWrapper.from_response(res)

    if dm.media_url
      client = User.egotter.api_client.twitter
      media = dm.retrieve_media(client)
      user = TwitterDB::User.find_by(uid: dm.sender_id)
      text = "uid=#{dm.sender_id} screen_name=#{user&.screen_name} text=#{dm.text}"

      if media.present?
        SlackBotClient.channel('general').upload_media(media, initial_comment: text)
      else
        text += " media=error"
        SlackBotClient.channel('general').post_message(text)
      end
    end
  rescue => e
    logger.warn "#{e.inspect} response=#{response.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end
end
