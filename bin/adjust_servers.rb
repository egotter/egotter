#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

require_relative '../deploy/lib/deploy'

SETTINGS = [
    [2, 1], # 09
    [2, 1], # 10
    [4, 1], # 11
    [4, 1], # 12
    [4, 1], # 13
    [2, 1], # 14
    [2, 1], # 15
    [2, 1], # 16
    [2, 1], # 17
    [2, 1], # 18
    [2, 1], # 19
    [4, 1], # 20
    [4, 1], # 21
    [4, 1], # 22
    [2, 1], # 23
    [2, 1], # 00
    [2, 1], # 01
    [2, 1], # 02
    [1, 0], # 03
    [1, 0], # 04
    [1, 0], # 05
    [2, 1], # 06
    [4, 1], # 07
    [4, 1], # 08
]

def current_hour
  Time.now.utc.hour
end

def adjust_servers(role, instance_type, count)
  prev_names = server_names(role, instance_type)

  if prev_names.size != count
    post("Adjust #{role} servers count=#{count} prev=#{prev_names}")
    Tasks::TaskBuilder.new('adjust' => true, 'role' => role, 'instance-type' => instance_type, 'count' => count, 'without-tag' => true).adjust_task.run

    cur_names = server_names(role, instance_type)
    post("`prev`=#{prev_names} `cur`=#{cur_names}")
  end
end

def server_names(role, instance_type)
  Tasks::TaskBuilder.new('list' => true, 'role' => role, 'instance-type' => instance_type).list_task.instance_names
end

def web_servers_count
  count = SETTINGS[current_hour][0]
  count += 1 if active_users > 300
  count += 1 if active_users > 400
  count
end

def sidekiq_servers_count
  count = SETTINGS[current_hour][1]
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
  role = ENV['ROLE']

  case role
  when 'web'
    adjust_servers('web', 't3.medium', web_servers_count)
  when 'sidekiq'
    adjust_servers('sidekiq', 'm5.large', sidekiq_servers_count)
  else
    raise "Invalid role value=#{role}"
  end
rescue => e
  post("Adjusting servers failed role=#{role} exception=#{e.inspect}")
  raise
end

if __FILE__ == $0
  Dir.chdir('/var/egotter') if Dir.exist?('/var/egotter')
  main
end
