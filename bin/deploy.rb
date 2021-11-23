#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'

require_relative '../deploy/lib/deploy'

STDOUT.sync = true

def print_help
  puts <<~'TEXT'
    Usage:
      deploy.rb --release --role web --hosts aaa,bbb,ccc
      deploy.rb --release --role web --hosts aaa,bbb,ccc --git-tag
      deploy.rb --release --role sidekiq --hosts aaa,bbb,ccc
      deploy.rb --release --role sidekiq --hosts aaa,bbb,ccc --git-tag

      deploy.rb --launch --role web
      deploy.rb --launch --role web --rotate
      deploy.rb --launch --role web --rotate --count 3
      deploy.rb --launch --role sidekiq --instance-type m5.large

      deploy.rb --sync --role web --instance-id i-0000
      deploy.rb --sync --role sidekiq --instance-id i-0000

      deploy.rb --list --role web
      deploy.rb --list --role sidekiq

      deploy.rb --terminate --role web
      deploy.rb --terminate --role web --count 3
      deploy.rb --terminate --role sidekiq --instance-id i-0000
  TEXT
end

def parse_params
  ARGV.getopts(
      'h',
      'help',
      'release',
      'role:',
      'hosts:',
      'git-tag',
      'launch-template:',
      'market-type:',
      'name-tag:',
      'security-group:',
      'subnet:',
      'target-group:',
      'availability-zone:',
      'instance-type:',
      'instance-id:',
      'instance-name:',
      'instance-name-regexp:',
      'delim:',
      'state:',
      'launch',
      'count:',
      'interval:',
      'adjust',
      'terminate',
      'sync',
      'rotate',
      'list',
      'without-tag',
      'debug',
  )
end

def git_tag?(params)
  !params['without-tag'] && !params['list'] && !params['terminate'] && params['role'] != 'plain'
end

def logger
  Deploy.logger
end

def main(params)
  lockfile = "deploy-#{params['role']}.pid"

  if params['h'] || params['help']
    print_help
    return
  end

  if !params['list'] && File.exist?(lockfile)
    puts 'Another deployment is already running'
    return
  end
  File.write(lockfile, Process.pid)

  logger.info "Deploy started params=#{params.compact.inspect}" unless params['list']
  task = Tasks::TaskBuilder.build(params)
  task.run
  logger.info "Deploy finished params=#{params.compact.inspect}" unless params['list']

  if git_tag?(params)
    system("git tag #{task.action}-#{params['role']}-#{Time.now.strftime("%Y-%m-%d_%H%M%S")}")
    system('git push origin --tags')
  end
ensure
  File.delete(lockfile) if File.exist?(lockfile)
end

if __FILE__ == $0
  main(parse_params)
end
