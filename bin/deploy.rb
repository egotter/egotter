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
      'launch-template-version:',
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
      'with-tag',
      'debug',
  )
end

def git_tag?(params)
  params.has_key?('with-tag') && params['with-tag'] && !params['list'] && !params['terminate'] && params['role'] != 'plain'
end

def main(params)
  if params['h'] || params['help']
    print_help
    return
  end

  if params['list']
    Tasks::TaskBuilder.build(params).run
    return
  end

  Deploy.with_lock("deploy-#{params['role']}.pid") do
    Deploy.logger.info "Deploy started params=#{params}"
    Tasks::TaskBuilder.build(params).run
    Deploy.logger.info "Deploy finished params=#{params}"
  end

  if git_tag?(params)
    system("git tag #{task.action}-#{params['role']}-#{Time.now.strftime("%Y-%m-%d_%H%M%S")}")
    system('git push origin --tags')
  end
end

if __FILE__ == $0
  main(parse_params)
end
