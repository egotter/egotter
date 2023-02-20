class SendReceivedMediaToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(json, options = {})
    dm = DirectMessageWrapper.from_json(json)
    return unless dm.media_url

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
  rescue => e
    Airbag.exception e, json: json
  end
end
