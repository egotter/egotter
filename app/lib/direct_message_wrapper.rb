class DirectMessageWrapper

  def initialize(response)
    raise EmptyResponse.new('Response is empty') if response.blank?
    @response = response
  end

  class << self
    def from_event(event)
      new(event: event)
    end

    def from_response(res)
      new(res)
    end
  end

  def id
    @response.dig(:event, :id)
  end

  def text
    @response.dig(:event, :message_create, :message_data, :text)
  end

  def truncated_message(at: 100)
    @truncated_message ||= text.to_s.remove(/\R/).gsub(%r{https?://[\S]+}, 'URL').truncate(at)
  end

  def sender_id
    @response.dig(:event, :message_create, :sender_id)&.to_i
  end

  def recipient_id
    @response.dig(:event, :message_create, :target, :recipient_id)&.to_i
  end

  def media_url
    @response.dig(:event, :message_create, :message_data, :attachment, :media, :media_url_https)
  end

  def retrieve_media(client)
    request = Twitter::REST::Request.new(client, :get, media_url)
    header = request.headers[:authorization]

    uri = URI.parse(media_url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.open_timeout = 3
    https.read_timeout = 3
    req = Net::HTTP::Get.new(uri)
    req['authorization'] = header

    res = https.start { https.request(req) }
    Media.new(res.body, res['content-type'])
  rescue => e
    nil
  end

  def dig(*args)
    @response.dig(*args)
  end

  def to_json
    @response.to_json
  end

  class Media
    attr_reader :content, :content_type

    def initialize(content, content_type)
      @content = content
      @content_type = content_type
    end

    def to_io
      StringIO.new(@content)
    end
  end

  class EmptyResponse < StandardError
  end
end
