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
    current_instances = fetch_instances

    if current_instances.size != ideal_count
      @market_type = 'not-spot' if current_instances.size == 0
      logger.log("Adjust #{@role} servers from #{current_instances.size} to #{ideal_count} current=#{current_instances.map(&:name)}")
      adjust_task.run
      logger.log("Finished prev=#{current_instances.map(&:name)} cur=#{fetch_instances.map(&:name)}", thread_ts: logger.last_thread)
    elsif current_instances.size == 1 && current_instances[0].market_type == 'spot'
      logger.log("Launch #{@role} server current=#{current_instances.map(&:name)}")
      launch_task.run
      logger.log("Finished prev=#{current_instances.map(&:name)} cur=#{fetch_instances.map(&:name)}", thread_ts: logger.last_thread)
    end
  end

  private

  def fetch_instances
    Tasks::TaskBuilder.new('list' => true, 'role' => @role).list_task.fetched_instances
  end

  def adjust_task
    params = {
        'adjust' => true,
        'role' => @role,
        'instance-type' => @instance_type,
        'count' => ideal_count,
        'market-type' => @market_type,
        'without-tag' => true,
    }
    Tasks::TaskBuilder.new(params).adjust_task
  end

  def launch_task
    params = {
        'launch' => true,
        'role' => @role,
        'instance-type' => @instance_type,
        'count' => 1,
        'market-type' => 'not-spot',
        'without-tag' => true,
    }
    Tasks::TaskBuilder.new(params).launch_task
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
