require 'logger'
require 'net/http'
require 'base64'
require 'aws-sdk-s3'

# Deploy
# cd lambda/og_image_proxy
# zip function.zip lambda_function.rb
# aws lambda update-function-code --function-name [NAME] --zip-file fileb://function.zip
# aws lambda publish-version --function-name [NAME]
# aws lambda update-alias --function-name [NAME] --name [ALIAS NAME] --function-version [VERSION]
# rm function.zip
#
# Show code diffs
# aws lambda get-function --function-name [NAME] | jq .Code.Location -r | xargs curl -s -o code.zip && unzip -p code.zip lambda_function.rb | colordiff -u lambda_function.rb -
# rm code.zip
def lambda_handler(event:, context:)
  logger = Logger.new(STDOUT)
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
    elsif resp.code == '404'
      logger.info { "Retry uid=#{uid} url=#{url} code=#{resp.code}" }
      sleep 3
    else
      logger.warn { "Stop retrying uid=#{uid} url=#{url} code=#{resp.code} body=#{resp.body}" }
    end
  end

  logger.info { "Retry exhausted uid=#{uid}" }
  NOT_FOUND
rescue => e
  logger.error "#{e.inspect} params=#{event.dig('queryStringParameters').inspect}"
  logger.error e.backtrace.join("\n") unless e.backtrace.nil?
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
