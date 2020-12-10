#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

def post(text)
  uri = URI.parse(ENV['SLACK_DEPLOY_URL'])
  Net::HTTP.post_form(uri, payload: {text: text}.to_json).body
end

token = `curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600"`
resp = `curl -s -H "X-aws-ec2-metadata-token: #{token}" http://169.254.169.254/latest/meta-data/spot/instance-action`

unless resp.include?('Not Found')
  instance_id = `curl -s -H "X-aws-ec2-metadata-token: #{token}" http://169.254.169.254/latest/meta-data/instance-id`
  message = "This instance is marked to be stopped or terminated id=#{instance_id}"
  puts post(message)
end
