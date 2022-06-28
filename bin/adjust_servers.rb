#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_BOT_TOKEN']
end

def logger
  @logger_instance ||= Class.new do
    def log(message, options = {})
      @response = Slack::Web::Client.new.chat_postMessage({channel: 'deploy', text: message}.merge(options))
    end

    def last_thread
      @response['ts']
    end
  end.new
end

require_relative '../deploy/lib/deploy'

# From 09:00 JST to 08:00 JST
WEB_SERVERS = [2, 2, 3, 3, 3, 2, 2, 2, 2, 2, 2, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 2, 3, 3]
SIDEKIQ_SERVERS = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2]

class Servers
  def initialize(role, instance_type, market_type)
    @role = role
    @instance_type = instance_type
    @market_type = market_type
  end

  def adjust
    prev_names = instance_names
    current_count = prev_names.size

    if current_count != ideal_count
      @market_type = 'not-spot' if current_count == 0
      logger.log("Adjust #{@role} servers from #{current_count} to #{ideal_count} current=#{prev_names}")
      run_task
      logger.log("Finish adjusting #{@role} servers prev=#{prev_names} cur=#{instance_names}", thread_ts: logger.last_thread)
    end
  end

  private

  def instance_names
    Tasks::TaskBuilder.new('list' => true, 'role' => @role, 'instance-type' => @instance_type).list_task.instance_names
  end

  def run_task
    params = {
        'adjust' => true,
        'role' => @role,
        'instance-type' => @instance_type,
        'count' => ideal_count,
        'market-type' => @market_type,
        'without-tag' => true,
    }
    Tasks::TaskBuilder.new(params).adjust_task.run
  end

  def ideal_count
    hour = Time.now.utc.hour

    if @role.include?('web')
      WEB_SERVERS[hour]
    elsif @role.include?('sidekiq')
      SIDEKIQ_SERVERS[hour]
    else
      raise "Invalid role value=#{@role}"
    end
  end
end

class App
  def initialize(role)
    @role = role
  end

  def run
    error_count ||= 0
    market_type ||= 'spot'

    if @role == 'web'
      instance_type = 't3.medium'
      market_type = 'not-spot'
    elsif @role == 'sidekiq'
      instance_type = 'm5.large'
    else
      raise "Invalid role value=#{@role}"
    end

    Servers.new(@role, instance_type, market_type).adjust
  rescue Aws::EC2::Errors::InsufficientInstanceCapacity => e
    logger.log("Retry adjusting #{@role} servers retries=#{error_count} exception=#{e.inspect}")
    market_type = 'not-spot'
    retry
  rescue => e
    if (error_count += 1) <= 3
      retry
    else
      logger.log("Adjusting #{@role} servers failed retries=#{error_count} exception=#{e.inspect}")
      raise
    end
  end
end

def main(role)
  lockfile = "deploy-#{role}.pid"

  if File.exist?(lockfile)
    logger.log("Another deployment is already running role=#{role}")
    return
  end

  begin
    File.write(lockfile, Process.pid)
    App.new(role).run
  ensure
    File.delete(lockfile) if File.exist?(lockfile)
  end
end

if __FILE__ == $0
  Dir.chdir('/var/egotter') if Dir.exist?('/var/egotter')
  main(ENV['ROLE'])
end
