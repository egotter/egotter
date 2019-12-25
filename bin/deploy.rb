#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'

require_relative '../lib/deploy'

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

hosts = params['hosts'].split(',')

case params['role']
when 'web'
  hosts.each { |host| Deploy::WebTask.new(host).run }

  if params['git-tag']
    system("git tag deploy-web-all-#{Time.now.to_i}")
    system('git push origin --tags')
  end
when 'sidekiq'
  hosts.each { |host| Deploy::SidekiqTask.new(host).run }

  if params['git-tag']
    system("git tag deploy-sidekiq-all-#{Time.now.to_i}")
    system('git push origin --tags')
  end
else
  puts "Invalid #{params.inspect}"
end
