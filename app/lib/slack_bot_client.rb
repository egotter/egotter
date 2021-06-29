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

  def post_message(text, options = {})
    @client.chat_postMessage({channel: @channel, text: text}.merge(options))
  end

  # TODO Not used
  def post_context_message(text, screen_name, icon_url, urls)
    mrkdwn_text = urls.map.with_index { |url, i| "<#{url}|url#{i + 1}>" }.join(' ') + ' ' + text
    block = {
        type: 'context',
        elements: [
            {type: 'image', image_url: icon_url, alt_text: "@#{screen_name}"},
            {type: 'mrkdwn', text: mrkdwn_text}
        ],
    }
    @client.chat_postMessage(channel: @channel, blocks: [block])
  end

  def upload_media(media, initial_comment: '')
    @client.files_upload(
        channels: @channel,
        content: media.content,
        initial_comment: initial_comment,
    )
  end

  def upload_snippet(text, initial_comment: '')
    @client.files_upload(
        channels: @channel,
        file: Faraday::UploadIO.new(StringIO.new(text), 'text/plain'),
        initial_comment: initial_comment,
    )
  end
end
