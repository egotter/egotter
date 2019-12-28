#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'

Dir['./deploy/taskbooks/*.rb'].each { |file| require file }

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
    'count:',
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
      aws.rb --launch --role web --rotate --count 3
      aws.rb --launch --role sidekiq --instance-type m5.large
      aws.rb --sync --role web --instance-id i-0000
      aws.rb --sync --role sidekiq --instance-id i-0000
      aws.rb --list --role web
      aws.rb --list --role sidekiq
      aws.rb --terminate --role web
      aws.rb --terminate --role web --count 3
      aws.rb --terminate --role sidekiq --instance-id i-0000
  TEXT

  exit
end

task = Taskbooks::AwsTask.build(params)
task.run

if %i(launch terminate sync).include?(task.kind)
  %x(git tag #{task.kind}-#{task.instance.name})
  %x(git push origin --tags)
end