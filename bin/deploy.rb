#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'

require_relative '../deploy/lib/deploy'

STDOUT.sync = true

def print_help
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
  !params['without-tag'] && !params['list'] && params['role'] != 'plain'
end

def main(params)
  if params['h'] || params['help']
    print_help
    return
  end

  Deploy.logger.info "Deploy started params=#{params.compact.inspect}" unless params['list']
  task = Tasks::TaskBuilder.build(params)
  task.run
  Deploy.logger.info "Deploy finished params=#{params.compact.inspect}" unless params['list']

  if git_tag?(params)
    system("git tag #{task.action}-#{params['role']}-#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}")
    system('git push origin --tags')
  end
end

if __FILE__ == $0
  main(parse_params)
end
