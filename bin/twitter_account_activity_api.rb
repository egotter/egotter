#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'
require 'base64'

# https://developer.twitter.com/en/docs/twitter-api/premium/account-activity-api/api-reference

def generate_token(key = ENV['TWITTER_CONSUMER_KEY'], secret = ENV['TWITTER_CONSUMER_SECRET'])
  # Twitter::REST::Client.new(consumer_key: 'ck', consumer_secret: 'cs').tap { |c| c.verify_credentials rescue nil }.bearer_token
  # Twitter::Headers
  cmd = %Q(curl -s -u "#{key}:#{secret}" --data 'grant_type=client_credentials' 'https://api.twitter.com/oauth2/token')
  JSON.parse(`#{cmd}`)['access_token']
end

# Returns all webhook URLs and their statuses
def list_webhooks(token)
  cmd = "curl -s --request GET --url https://api.twitter.com/1.1/account_activity/all/webhooks.json --header 'Authorization: Bearer #{token}'"
  JSON.parse(`#{cmd}`)
end

# Subscribes an application to an account's events
def subscribe!(env_name, consumer_key = ENV['TWITTER_CONSUMER_KEY'], consumer_secret = ENV['TWITTER_CONSUMER_SECRET'], access_token = ENV['TWITTER_ACCESS_TOKEN'], access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET'])
  request_method = 'POST'
  url = "https://api.twitter.com/1.1/account_activity/all/#{env_name}/subscriptions.json"
  header = oauth_header(request_method, url, consumer_key, consumer_secret, access_token, access_token_secret)
  cmd = %Q(curl -s -o /dev/null -w "%{http_code}" --request #{request_method} --url #{url} --header '#{header}')
  `#{cmd}` == '204'
end

# Returns a count of currently active subscriptions
def subscriptions_count(token)
  cmd = "curl -s --request GET --url https://api.twitter.com/1.1/account_activity/all/subscriptions/count.json --header 'Authorization: Bearer #{token}'"
  JSON.parse(`#{cmd}`)
end

# Check to see if a webhook is subscribed to an account
def is_subscribing?(env_name, consumer_key = ENV['TWITTER_CONSUMER_KEY'], consumer_secret = ENV['TWITTER_CONSUMER_SECRET'], access_token = ENV['TWITTER_ACCESS_TOKEN'], access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET'])
  request_method = 'GET'
  url = "https://api.twitter.com/1.1/account_activity/all/#{env_name}/subscriptions.json"
  header = oauth_header(request_method, url, consumer_key, consumer_secret, access_token, access_token_secret)
  cmd = %Q(curl -s -o /dev/null -w "%{http_code}" --request #{request_method} --url #{url} --header '#{header}')
  `#{cmd}` == '204'
end

# Returns a list of currently active subscriptions
def list_subscriptions(token, env_name)
  cmd = "curl -s --request GET --url https://api.twitter.com/1.1/account_activity/all/#{env_name}/subscriptions/list.json --header 'Authorization: Bearer #{token}'"
  JSON.parse(`#{cmd}`)
end

# Deactivates a subscription using application-only OAuth
def delete_subscribe(token, env_name, user_id)
  cmd = "curl -s --request DELETE --url https://api.twitter.com/1.1/account_activity/all/#{env_name}/subscriptions/#{user_id}.json --header 'Authorization: Bearer #{token}'"
  `#{cmd}` == '204'
end

def oauth_header(request_method, uri, consumer_key, consumer_secret, access_token, access_token_secret)
  params = {
      oauth_consumer_key: consumer_key,
      oauth_nonce: Time.now.utc.to_i,
      oauth_signature_method: 'HMAC-SHA1',
      oauth_timestamp: Time.now.utc.to_i,
      oauth_token: access_token,
      oauth_version: '1.0',
  }
  encoded_params = URI.encode_www_form_component(params.map { |k, v| "#{k}=#{v}" }.join('&'))
  encoded_uri = URI.encode_www_form_component(uri)
  signature_base = request_method + '&' + encoded_uri + '&' + encoded_params
  signature_key = consumer_secret + '&' + access_token_secret
  signature = OpenSSL::HMAC.digest('sha1', signature_key, signature_base)
  encoded_signature = URI.encode_www_form_component(Base64.strict_encode64(signature))
  'Authorization: OAuth ' + params.merge(oauth_signature: encoded_signature).map { |k, v| %Q(#{k}="#{v}") }.join(', ')
end

def bearer_token
  ENV['TOKEN'] || generate_token
end

def main
  case ENV['ACTION']
  when 'generate_token'
    puts generate_token
  when 'list_webhooks'
    pp list_webhooks(bearer_token)
  when 'subscribe'
    pp subscribe!(ENV['ENV_NAME'])
  when 'subscriptions_count'
    pp subscriptions_count(bearer_token)
  when 'is_subscribing'
    pp is_subscribing?(ENV['ENV_NAME'])
  when 'list_subscriptions'
    pp list_subscriptions(bearer_token, ENV['ENV_NAME'])
  when 'delete_subscribe'
    pp delete_subscribe(bearer_token, ENV['ENV_NAME'], ENV['USER_ID'])
  else
    raise "Invalid action value=#{ENV['ACTION']}"
  end
end

if __FILE__ == $0
  main
end
