#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

def post_message(text)
  uri = URI.parse(ENV['SLACK_NOTIFY_INTERRUPTION_URL'])
  puts Net::HTTP.post_form(uri, payload: {text: "#{instance_id} #{instance_name}: #{text}"}.to_json).body
end

def instance_token
  @instance_token ||= `curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600"`
end

def instance_id
  @instance_id ||= `curl -s -H "X-aws-ec2-metadata-token: #{instance_token}" http://169.254.169.254/latest/meta-data/instance-id`.chomp
end

def instance_name
  @instance_name ||= `aws ec2 describe-tags --filters "Name=resource-id,Values=#{instance_id}" "Name=key,Values=Name" --region ap-northeast-1 --query="Tags[0].Value"`.gsub(/["\n]/, '')
end

def marked_to_be_terminated?
  resp = `curl -s -H "X-aws-ec2-metadata-token: #{instance_token}" http://169.254.169.254/latest/meta-data/spot/instance-action`
  !resp.include?('Not Found')
end

def web_instance?
  instance_name.include?('web')
end

def sidekiq_instance?
  instance_name.include?('sidekiq')
end

class UpstartUtil
  def self.running?(name)
    `sudo status #{name} 2>&1`.include?('start/running')
  end

  def self.stop(name)
    `sudo stop #{name} 2>&1`.include?('stop/waiting')
  end
end

def web_running?
  UpstartUtil.running?('puma')
end

def sidekiq_running?(name)
  UpstartUtil.running?(name)
end

def stop_web
  web_resource = WebResource.new(instance_id)

  if web_resource.registered?
    web_resource.stop
    post_message('This instance is deregistered')
  else
    post_message('This instance is not registered')
  end

  if UpstartUtil.running?('puma')
    UpstartUtil.stop('puma')
    post_message('puma is stopped')
  else
    post_message('puma is not running')
  end
end

def stop_sidekiq
  %w(sidekiq_misc sidekiq).each do |name|
    if UpstartUtil.running?(name)
      UpstartUtil.stop(name)
      post_message("#{name} is stopped")
    else
      post_message("#{name} is not running")
    end
  end
end

class WebResource
  def initialize(instance_id)
    @instance_id = instance_id
  end

  def registered?
    target_health == 'healthy'
  end

  def stop
    deregister
    wait_until_deregistered
  end

  private

  def target_health
    resp = `aws elbv2 describe-target-health --target-group-arn #{target_group} --targets Id=#{@instance_id} --region ap-northeast-1`
    instance_data = JSON.parse(resp)['TargetHealthDescriptions'].find { |data| data['Target']['Id'] == @instance_id }
    instance_data && instance_data['TargetHealth']['State']
  end

  def deregister
    `aws elbv2 deregister-targets --target-group-arn #{target_group} --targets Id=#{@instance_id} --region ap-northeast-1`
  end

  def wait_until_deregistered
    `aws elbv2 wait target-deregistered --target-group-arn #{target_group} --targets Id=#{@instance_id} --region ap-northeast-1`
  end

  def target_group
    @target_group ||= `aws elbv2 describe-target-groups --region ap-northeast-1 --names egotter --query="TargetGroups[0].TargetGroupArn"`.gsub(/["\n]/, '')
  end
end

def main
  return unless marked_to_be_terminated?

  post_message('This instance is marked to be terminated')

  if web_instance?
    stop_web
  elsif sidekiq_instance?
    stop_sidekiq
  end

  post_message('Finished')
rescue => e
  post_message("An error occurred exception=#{e.inspect}")
end

if __FILE__ == $0
  main
end

