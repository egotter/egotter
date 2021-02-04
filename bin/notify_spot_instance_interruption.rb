#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

def post_message(text)
  uri = URI.parse(ENV['SLACK_NOTIFY_INTERRUPTION_URL'])
  puts Net::HTTP.post_form(uri, payload: {text: text}.to_json).body
end

def fetch_token
  `curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600"`
end

def fetch_instance_id(token)
  `curl -s -H "X-aws-ec2-metadata-token: #{token}" http://169.254.169.254/latest/meta-data/instance-id`.chomp
rescue => e
  'error'
end

def fetch_name_tag(instance_id)
  `aws ec2 describe-tags --filters "Name=resource-id,Values=#{instance_id}" "Name=key,Values=Name" --region ap-northeast-1 --query="Tags[0].Value"`.gsub(/["\n]/, '')
rescue => e
  'error'
end

def fetch_target_group_arn
  `aws elbv2 describe-target-groups --region ap-northeast-1 --names egotter --query="TargetGroups[0].TargetGroupArn"`.gsub(/["\n]/, '')
rescue => e
  'error'
end

def deregister_target(target_group_arn, instance_id)
  `aws elbv2 deregister-targets --target-group-arn #{target_group_arn} --targets Id=#{instance_id} --region ap-northeast-1`
rescue => e
  'error'
end

def main
  token = fetch_token
  resp = `curl -s -H "X-aws-ec2-metadata-token: #{token}" http://169.254.169.254/latest/meta-data/spot/instance-action`

  unless resp.include?('Not Found')
    instance_id = fetch_instance_id(token)
    name = fetch_name_tag(instance_id)
    post_message("This instance is marked to be terminated id=#{instance_id} name=#{name}")

    if name.include?('web')
      arn = fetch_target_group_arn
      deregister_target(arn, instance_id)
      post_message("An instance is deregistered id=#{instance_id} name=#{name}")
    elsif name.include?('sidekiq')
      `sudo stop sidekiq_misc`
      `sudo stop sidekiq`
      post_message("The sidekiq processes are stopped id=#{instance_id} name=#{name}")
    end
  end
end

if __FILE__ == $0
  main
end

