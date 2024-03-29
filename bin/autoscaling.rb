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
    def info(msg, without_slack: false)
      Deploy.logger.info msg
      post_message(msg) unless without_slack
    end

    def warn(msg, without_slack: false)
      Deploy.logger.warn msg
      post_message(msg) unless without_slack
    end

    def post_message(msg)
      options = {channel: 'deploy', text: msg}
      options[:thread_ts] = @response['ts'] if @response
      @response = Slack::Web::Client.new.chat_postMessage(options)
    end
  end.new
end

require_relative '../deploy/lib/deploy'

# From 09:00 JST to 08:00 JST
WEB_SERVERS = [1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
SIDEKIQ_SERVERS = [1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

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
      logger.info("Adjust #{@role} servers from #{current_instances.size} to #{ideal_count} current=#{current_instances.map(&:name)}")
      adjust_task.run
      logger.info("Finished prev=#{current_instances.map(&:name)} cur=#{fetch_instances.map(&:name)}")
    elsif current_instances.all? { |i| i.instance_lifecycle == 'spot' }
      logger.info("Launch #{@role} server current=#{current_instances.map(&:name)}")
      launch_task.run
      logger.info("Finished prev=#{current_instances.map(&:name)} cur=#{fetch_instances.map(&:name)}")
    else
      logger.info("Neither start nor stop is performed cur=#{current_instances.map(&:name)}", without_slack: true)
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
      instance_type = 't3.small'
    elsif @role == 'sidekiq'
      instance_type = 't3.small'
    else
      raise "Invalid role value=#{@role}"
    end

    Servers.new(@role, instance_type, market_type).adjust
  rescue Aws::EC2::Errors::InsufficientInstanceCapacity => e
    logger.warn("Retry adjusting role=#{@role} error_count=#{error_count} exception=#{e.inspect}")
    error_count += 1
    market_type = 'not-spot'
    retry
  rescue => e
    if (error_count += 1) <= 3
      logger.warn("Retry adjusting role=#{@role} error_count=#{error_count} exception=#{e.inspect}")
      retry
    else
      logger.warn("Adjusting failed role=#{@role} error_count=#{error_count} exception=#{e.inspect}")
      raise
    end
  end
end

def main(role)
  if role.nil? || role.empty?
    logger.info "#{$0}: ROLE not found"
    return
  end

  Deploy.with_lock("deploy-#{role}.pid") do
    App.new(role).run
  end
rescue => e
  logger.warn("Failed role=#{role} exception=#{e.inspect}")
end

if __FILE__ == $0
  Dir.chdir('/var/egotter') if Dir.exist?('/var/egotter')
  main(ARGV[0] || ENV['ROLE'])
end
