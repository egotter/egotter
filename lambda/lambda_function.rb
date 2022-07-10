require 'net/http'
require 'base64'
require 'aws-sdk-s3'

def lambda_handler(event:, context:)
  uid = event.dig('queryStringParameters', 'uid')

  unless uid.to_s.match?(/\A[0-9]{1,30}\z/)
    return BAD_REQUEST
  end

  url = close_friends_og_image_url(uid: uid)

  5.times do
    resp = get_response(url, context)

    if resp.code == '200'
      key = JSON.parse(resp.body)['key']
      return SUCCESS.dup.tap { |res| res[:body] = load_image(key) }
    end

    sleep 3
  end

  NOT_FOUND
rescue => e
  puts "#{e.inspect} params=#{event.dig('queryStringParameters').inspect}"
  puts e.backtrace.join("\n")
  INTERNAL_SERVER_ERROR
end

def close_friends_og_image_url(uid:)
  "#{ENV['OG_IMAGE_URL']}#{uid}"
end

def get_response(url, context)
  uri = URI.parse(url)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = "#{context.function_name} #{context.function_version}"
  https.start { https.request(req) }
end

def load_image(key)
  s3 = Aws::S3::Resource.new(region: ENV['REGION']).bucket(ENV['BUCKET'])
  if (obj = s3.object(key)).exists?
    Base64.strict_encode64(obj.get.body.read)
  end
end

SUCCESS = {
    statusCode: 200,
    headers: {'Content-Type': 'image/png'},
    isBase64Encoded: true,
    body: nil,
}
BAD_REQUEST = {statusCode: 400, headers: {'Content-Type': 'text/plain'}, body: 'Bad request'}
NOT_FOUND = {statusCode: 404, headers: {'Content-Type': 'text/plain'}, body: 'Not found'}
INTERNAL_SERVER_ERROR = {statusCode: 500, headers: {'Content-Type': 'text/plain'}, body: 'Internal server error'}
