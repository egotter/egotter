#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'

require_relative '../lib/egotter/deploy'

STDOUT.sync = true

params = ARGV.getopts('h', 'help', 'role:', 'hosts:')

if params['h'] || params['help']
  puts <<~'TEXT'
    Usage:
      deploy.rb --role web --hosts aaa,bbb,ccc
      deploy.rb --role sidekiq --hosts aaa,bbb,ccc
  TEXT

  exit
end

hosts = params['hosts'].split(',')

case params['role']
when 'web'
  hosts.each { |host| ::Egotter::Deploy::Web.new(host).deploy }
  system("git tag deploy-web-all-#{Time.now.to_i}")
  system('git push origin --tags')

when 'sidekiq'
  hosts.each { |host| Egotter::Deploy::Sidekiq.new(host).deploy }
  system("git tag deploy-sidekiq-all-#{Time.now.to_i}")
  system('git push origin --tags')

else
  puts "Invalid #{params.inspect}"
end
