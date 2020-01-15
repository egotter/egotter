#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'

require_relative '../taskbooks/all'

STDOUT.sync = true

params = ARGV.getopts(
    'h',
    'help',
    'release',
    'role:',
    'hosts:',
    'git-tag',
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
    'rotate',
    'list',
    'debug',
)

if params['h'] || params['help']
  puts <<~'TEXT'
    Usage:
      egotter.rb --release --role web --hosts aaa,bbb,ccc
      egotter.rb --release --role web --hosts aaa,bbb,ccc --git-tag
      egotter.rb --release --role sidekiq --hosts aaa,bbb,ccc
      egotter.rb --release --role sidekiq --hosts aaa,bbb,ccc --git-tag

      egotter.rb --launch --role web
      egotter.rb --launch --role web --rotate
      egotter.rb --launch --role web --rotate --count 3
      egotter.rb --launch --role sidekiq --instance-type m5.large

      egotter.rb --sync --role web --instance-id i-0000
      egotter.rb --sync --role sidekiq --instance-id i-0000

      egotter.rb --list --role web
      egotter.rb --list --role sidekiq

      egotter.rb --terminate --role web
      egotter.rb --terminate --role web --count 3
      egotter.rb --terminate --role sidekiq --instance-id i-0000
  TEXT

  exit
end

if params['release']
  task = Taskbooks::ReleaseTask.build(params)
  task.run

  if params['git-tag']
    system("git tag deploy-#{params['role']}-all-#{Time.now.to_i}")
    system('git push origin --tags')
  end
else
  task = Taskbooks::AwsTask.build(params)
  task.run

  if %i(launch terminate sync).include?(task.kind)
    %x(git tag #{task.kind}-#{task.instance.name})
    %x(git push origin --tags)
  end
end
