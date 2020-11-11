require 'net/http'

class SlackBotClient
  def initialize(channel:)
    @channel = "##{channel}"
    @client = Slack::Web::Client.new
  end

  class << self
    def channel(name)
      new(channel: name)
    end
  end

  def post_message(text)
    @client.chat_postMessage(channel: @channel, text: text)
  end

  def upload_media(media, initial_comment: '')
    @client.files_upload(
        channels: @channel,
        file: Faraday::UploadIO.new(media.to_io, media.content_type),
        initial_comment: initial_comment,
    )
  end
end
