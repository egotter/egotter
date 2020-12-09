require 'net/http'
require 'base64'
require 'aws-sdk-s3'

def lambda_handler(event:, context:)
  params = Params.from_event(event)

  unless params.valid?
    return BadRequest.new.to_response
  end

  url = close_friends_og_image_url(uid: params.uid)

  5.times do
    resp = Net::HTTP.get_response(url)

    if resp.code == '200'
      key = JSON.parse(resp.body)['key']
      return Image.new(key).to_response
    end

    sleep 3
  end

  NotFound.new.to_response
rescue => e
  puts "#{e.inspect} params=#{event.dig('queryStringParameters').inspect}"
  puts e.backtrace.join("\n")
  InternalServerError.new.to_response
end

def close_friends_og_image_url(uid:)
  URI.parse("#{ENV['OG_IMAGE_URL']}#{uid}")
end

class Params
  attr_reader :uid

  def initialize(uid:)
    @uid = uid
  end

  class << self
    def from_event(event)
      uid = event.dig('queryStringParameters', 'uid')
      new(uid: uid)
    end
  end

  def valid?
    @uid.to_s.match?(/\A[0-9]{1,30}\z/)
  end
end

class Image
  def initialize(key)
    @key = key
  end

  def load
    s3 = Aws::S3::Resource.new(region: ENV['REGION']).bucket(ENV['BUCKET'])
    obj = s3.object(@key)
    if obj.exists?
      @binary = obj.get.body.read
    end
  end

  def to_response
    load unless @binary

    {
        statusCode: 200,
        headers: {'Content-Type': 'image/png'},
        isBase64Encoded: true,
        body: Base64.strict_encode64(@binary),
    }
  end
end

class ErrorResponse
  def initialize(code, message)
    @code = code
    @message = message
  end

  def to_response
    {
        statusCode: @code,
        headers: {'Content-Type': 'text/plain'},
        body: @message
    }
  end
end

class BadRequest < ErrorResponse
  def initialize
    super(400, 'Bad request')
  end
end

class NotFound < ErrorResponse
  def initialize
    super(404, 'Not found')
  end
end

class InternalServerError < ErrorResponse
  def initialize
    super(500, 'Internal server error')
  end
end
