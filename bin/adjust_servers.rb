#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_BOT_TOKEN']
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
    prev_names = names
    current_count = prev_names.size

    if current_count != ideal_count
      res = post("Adjust #{@role} servers from #{current_count} to #{ideal_count} current=#{prev_names}")
      run_task
      post("Finish adjusting #{@role} servers prev=#{prev_names} cur=#{names}", thread_ts: res['ts'])
    end
  end

  private

  def names
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
    if @role.include?('web')
      unless @ideal_count
        count = WEB_SERVERS[current_hour]
        count += 1 if active_users > 400
        @ideal_count = count
      end
    elsif @role.include?('sidekiq')
      unless @ideal_count
        count = SIDEKIQ_SERVERS[current_hour]
        count += 1 if remaining_creation_jobs > 1000
        count += 1 if remaining_creation_jobs > 10000
        @ideal_count = count
      end
    else
      raise "Invalid role value=#{@role}"
    end

    @ideal_count
  end

  def active_users
    unless @active_users
      uri = URI.parse('https://egotter.com/api/v1/access_stats?key=' + ENV['STATS_API_KEY'])
      @active_users = JSON.parse(Net::HTTP.get(uri))['active_users']
    end
    @active_users
  rescue => e
    0
  end

  def remaining_creation_jobs
    unless @remaining_creation_jobs
      uri = URI.parse('https://egotter.com/api/v1/report_stats?key=' + ENV['STATS_API_KEY'])
      @remaining_creation_jobs = JSON.parse(Net::HTTP.get(uri))['CreateReportTwitterUserWorker']
    end
    @remaining_creation_jobs
  rescue => e
    0
  end

  def current_hour
    Time.now.utc.hour
  end
end

def post(text, thread_ts: nil)
  Slack::Web::Client.new.chat_postMessage({channel: 'deploy', text: text, thread_ts: thread_ts})
end

class App
  def initialize(role)
    @role = role
  end

  def run
    retries ||= 3
    market_type ||= 'spot'

    case @role
    when 'web'
      Servers.new(@role, 't3.medium', market_type).adjust
    when 'sidekiq'
      Servers.new(@role, 'm5.large', market_type).adjust
    else
      raise "Invalid role value=#{@role}"
    end
  rescue => e
    if e.class == Aws::EC2::Errors::InsufficientInstanceCapacity && (retries -= 1) > 0
      post("Retry adjusting #{@role} servers retries=#{retries} exception=#{e.inspect}")
      market_type = 'not-spot'
      retry
    else
      post("Adjusting #{@role} servers failed retries=#{retries} exception=#{e.inspect}")
      raise
    end
  end
end

def main(role)
  lockfile = "deploy-#{role}.pid"
  if File.exist?(lockfile)
    post("Another deployment is already running role=#{role}")
    return
  end
  File.write(lockfile, Process.pid)

  App.new(role).run
ensure
  File.delete(lockfile) if File.exist?(lockfile)
end

if __FILE__ == $0
  Dir.chdir('/var/egotter') if Dir.exist?('/var/egotter')
  main(ENV['ROLE'])
end
