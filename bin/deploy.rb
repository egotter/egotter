#!/usr/bin/env ruby

require 'optparse'

require_relative '../lib/egotter/deploy'

STDOUT.sync = true

params = ARGV.getopts('r:', 'role:', 'hosts:')
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
