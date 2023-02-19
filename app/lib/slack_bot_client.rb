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

  def channel
    @client.conversations_list.channels.find { |c| c.name == @channel.slice(1..-1) }
  end

  def messages(count: 100, latest: nil)
    collection = []
    options = {channel: channel.id, limit: 100, latest: latest}.compact

    while collection.size < count
      response = @client.conversations_history(options)

      if response.messages.empty?
        break
      end

      collection.concat(response.messages)

      if options[:latest]
        options[:latest] = response.messages.last.ts
      else
        options[:cursor] = response.response_metadata.next_cursor
      end
    end

    collection.take(count)
  end

  def delete_message(ts)
    @client.chat_delete(channel: channel.id, ts: ts)
  end

  def post_message(text, options = {})
    @client.chat_postMessage({channel: @channel, text: text}.merge(options))
  ensure
    SlackLog.create(channel: @channel, message: text, time: Time.zone.now) rescue nil
  end

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

  # upload_media(IO.binread('xxx.jpg'))
  def upload_media(media, initial_comment: '')
    @client.files_upload(
        channels: @channel,
        content: media.respond_to?(:content) ? media.content : media,
        initial_comment: initial_comment,
    )
  end

  # Not used
  def upload_snippet(text, initial_comment: '')
    response = @client.files_upload(
        channels: @channel,
        file: Faraday::UploadIO.new(StringIO.new(text), 'text/plain'),
        initial_comment: initial_comment,
    )
    # begin
    #   channel = response.file.channels[0]
    #   ts = response.file.shares.public[channel][0]['ts']
    #   SlackMessage.create(channel: @channel, message: initial_comment, properties: {snippet: text, response: {channel: channel, ts: ts}})
    # rescue => e
    # end
  end
end
