#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

class App
  def marked_to_be_terminated?
    resp = `curl -s -H "X-aws-ec2-metadata-token: #{token}" http://169.254.169.254/latest/meta-data/spot/instance-action`
    !resp.include?('Not Found')
  end

  def instance_id
    @instance_id ||= `curl -s -H "X-aws-ec2-metadata-token: #{token}" http://169.254.169.254/latest/meta-data/instance-id`.chomp
  end

  def instance_name
    @instance_name ||= `aws ec2 describe-tags --filters "Name=resource-id,Values=#{instance_id}" "Name=key,Values=Name" --region ap-northeast-1 --query="Tags[0].Value"`.gsub(/["\n]/, '')
  end

  def stop
    if instance_name.include?('web')
      WebProcess.new(instance_id).stop
    elsif instance_name.include?('sidekiq')
      Process.new('sidekiq_misc').stop
      Process.new('sidekiq').stop
    end
  end

  def to_s
    "(#{instance_id} #{instance_name})"
  end

  private

  def token
    @token ||= `curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600"`
  end

  class Slack
    class << self
      def post(text)
        uri = URI.parse(ENV['SLACK_NOTIFY_INTERRUPTION_URL'])
        puts Net::HTTP.post_form(uri, payload: {text: text}.to_json).body
      end
    end
  end

  class Process
    def initialize(process_name)
      @process_name = process_name
    end

    def stop
      if `sudo status #{@process_name}`.include?('start/running')
        `sudo stop #{@process_name}`
      end
    end
  end

  class WebProcess
    def initialize(instance_id)
      @instance_id = instance_id
      @target_group = target_group
    end

    def stop
      deregister
      wait_until_deregistered
      sleep(10) # TODO Remove this line if the #wait_until_deregistered works correctly
      Process.new('puma').stop
    end

    private

    def deregister
      `aws elbv2 deregister-targets --target-group-arn #{@target_group} --targets Id=#{@instance_id} --region ap-northeast-1`
    end

    def wait_until_deregistered
      `aws elbv2 wait target-deregistered --target-group-arn #{@target_group} --targets Id=#{@instance_id} --region ap-northeast-1`
    end

    def target_group
      `aws elbv2 describe-target-groups --region ap-northeast-1 --names egotter --query="TargetGroups[0].TargetGroupArn"`.gsub(/["\n]/, '')
    end
  end
end

def main
  app = App.new
  return unless app.marked_to_be_terminated?

  App::Slack.post("This instance is marked to be terminated app=#{app}")

  app.stop
  App::Slack.post("The app is stopped app=#{app}")
rescue => e
  App::Slack.post("An error occurred exception=#{e.inspect}")
end

if __FILE__ == $0
  main
end

