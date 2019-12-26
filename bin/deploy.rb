#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'

require_relative '../deploy/deploy'

STDOUT.sync = true

params = ARGV.getopts(
    'h',
    'help',
    'role:',
    'hosts:',
    'git-tag',
)

if params['h'] || params['help']
  puts <<~'TEXT'
    Usage:
      deploy.rb --role web --hosts aaa,bbb,ccc
      deploy.rb --role web --hosts aaa,bbb,ccc --git-tag
      deploy.rb --role sidekiq --hosts aaa,bbb,ccc
      deploy.rb --role sidekiq --hosts aaa,bbb,ccc --git-tag
  TEXT

  exit
end

tasks = DeployTask.build(params)
tasks.each(&:run)

if params['git-tag']
  system("git tag deploy-#{params['role']}-all-#{Time.now.to_i}")
  system('git push origin --tags')
end
