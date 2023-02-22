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

    slack = SlackBotClient.channel('general')

    if media.present?
      begin
        slack.upload_media(media, initial_comment: text)
      rescue => e
        slack.post_message(text + ' media=something_error')
      end
    else
      slack.post_message(text + ' media=fetching_failed')
    end
  rescue => e
    Airbag.exception e, json: json
  end
end
