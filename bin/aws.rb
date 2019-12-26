#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'

require_relative '../lib/aws'

STDOUT.sync = true

params = ARGV.getopts(
    'h',
    'help',
    'launch-template:',
    'name-tag:',
    'security-group:',
    'subnet:',
    'target-group:',
    'availability-zone:',
    'instance-type:',
    'instance-id:',
    'instance-name:',
    'delim:',
    'state:',
    'launch',
    'terminate',
    'sync',
    'role:',
    'rotate',
    'list',
    'debug',
)

if params['h'] || params['help']
  puts <<~'TEXT'
    Usage:
      aws.rb --launch --role web
      aws.rb --launch --role web --rotate
      aws.rb --launch --role sidekiq --instance-type m5.large
      aws.rb --sync --role web --instance-id i-0000
      aws.rb --sync --role sidekiq --instance-id i-0000
      aws.rb --list
      aws.rb --terminate --role web
      aws.rb --terminate --role sidekiq --instance-id i-0000
  TEXT

  exit
end

if params['launch']
  task = LaunchTask.build(params)
  instance = task.run

  %x(git tag launch-#{instance.name})
  %x(git push origin --tags)

elsif params['terminate']
  task = TerminateTask.build(params)
  instance = task.run

  %x(git tag terminate-#{instance.name})
  %x(git push origin --tags)

elsif params['sync']
  if params['role'] == 'web'
    ::Egotter::Install::Web.new(params['instance-id']).sync
  elsif params['role'] == 'sidekiq'
    ::Egotter::Install::Sidekiq.new(params['instance-id']).sync
  else
    raise "Invalid role #{params['role']}"
  end
elsif params['list']
  state = params['state'].to_s.empty? ? 'healthy' : params['state']
  delim = params['delim'] || ' '

  target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
  puts ::Egotter::Aws::TargetGroup.new(target_group_arn).instances(state: state).map(&:name).join(delim)
elsif params['debug']
end
