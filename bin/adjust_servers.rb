#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

require_relative '../deploy/lib/deploy'

# From 09:00 JST to 08:00 JST
WEB_SERVERS = [2, 2, 3, 3, 3, 2, 2, 2, 2, 2, 2, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 2, 3, 3]
SIDEKIQ_SERVERS = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1]

def current_hour
  Time.now.utc.hour
end

def adjust_servers(role, instance_type, count, market_type)
  prev_names = server_names(role, instance_type)

  if prev_names.size != count
    post("Adjust #{role} servers from #{prev_names.size} to #{count} current=#{prev_names}")

    task_params = {
        'adjust' => true,
        'role' => role,
        'instance-type' => instance_type,
        'count' => count,
        'market-type' => market_type,
        'without-tag' => true,
    }
    Tasks::TaskBuilder.new(task_params).adjust_task.run

    cur_names = server_names(role, instance_type)
    post("Finish adjusting #{role} servers prev=#{prev_names} cur=#{cur_names}")
  end
end

def server_names(role, instance_type)
  Tasks::TaskBuilder.new('list' => true, 'role' => role, 'instance-type' => instance_type).list_task.instance_names
end

def web_servers_count
  count = WEB_SERVERS[current_hour]
  count += 1 if active_users > 400
  count
end

def sidekiq_servers_count
  count = SIDEKIQ_SERVERS[current_hour]
  count += 1 if remaining_creation_jobs > 1000
  count += 1 if remaining_creation_jobs > 10000
  count
end

def post(text)
  uri = URI.parse(ENV['SLACK_DEPLOY_URL'])
  Net::HTTP.post_form(uri, payload: {text: text}.to_json).body
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

def main
  retries ||= 3
  market_type ||= 'spot'
  role = ENV['ROLE']

  case role
  when 'web'
    adjust_servers('web', 't3.medium', web_servers_count, market_type)
  when 'sidekiq'
    adjust_servers('sidekiq', 'm5.large', sidekiq_servers_count, market_type)
  else
    raise "Invalid role value=#{role}"
  end
rescue => e
  if e.class == Aws::EC2::Errors::InsufficientInstanceCapacity && (retries -= 1) > 0
    post("Retry adjusting #{role} servers retries=#{retries} exception=#{e.inspect}")
    market_type = 'not-spot'
    retry
  else
    post("Adjusting #{role} servers failed retries=#{retries} exception=#{e.inspect}")
    raise
  end
end

if __FILE__ == $0
  Dir.chdir('/var/egotter') if Dir.exist?('/var/egotter')
  main
end
