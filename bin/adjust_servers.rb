#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

SETTINGS = [
    [2, 2], # 09
    [2, 1], # 10
    [3, 3], # 11
    [3, 3], # 12
    [3, 3], # 13
    [2, 1], # 14
    [2, 1], # 15
    [2, 1], # 16
    [2, 1], # 17
    [2, 1], # 18
    [2, 1], # 19
    [3, 3], # 20
    [3, 3], # 21
    [3, 3], # 22
    [2, 2], # 23
    [2, 2], # 00
    [2, 2], # 01
    [2, 1], # 02
    [2, 1], # 03
    [2, 1], # 04
    [2, 1], # 05
    [2, 1], # 06
    [3, 3], # 07
    [3, 3], # 08
]

def now
  Time.now.utc
end

def adjust_server(role, instance_type, num, dry_run)
  cmd = "cd /var/egotter && /usr/local/bin/bundle exec bin/deploy.rb --adjust --role #{role} --instance-type #{instance_type} --count #{num}"
  dry_run ? (puts cmd) : system(cmd)
  cmd
end

def adjust_web(dry_run)
  result = adjust_server('web', 't3.medium', SETTINGS[now.hour][0], dry_run)
  post result
end

def adjust_sidekiq(dry_run)
  result = adjust_server('sidekiq', 'm5.large', SETTINGS[now.hour][1], dry_run)
  post result
end

def post(text)
  uri = URI.parse(ENV['SLACK_DEPLOY_URL'])
  Net::HTTP.post_form(uri, payload: {text: text}.to_json).body
end

def main
  dry_run = ENV['DRY_RUN'] == 'true'

  case ENV['ROLE']
  when 'web'
    adjust_web(dry_run)
  when 'sidekiq'
    adjust_sidekiq(dry_run)
  else
    raise "Invalid role value=#{ENV['ROLE']}"
  end
end

main
