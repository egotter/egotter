#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'
require 'base64'
require 'erb'

require_relative '../lib/secret_file'

require_relative '../lib/egotter/aws'
require_relative '../lib/egotter/launch'
require_relative '../lib/egotter/install'

STDOUT.sync = true

if __FILE__ == $0
  def append_to_ssh_config(id, host, public_ip)
    text = <<~"TEXT"
      # #{id}
      Host #{host}
        HostName     #{public_ip}
        IdentityFile ~/.ssh/egotter.pem
        User         ec2-user
    TEXT

    puts text
    File.open('./ssh_config', 'a') { |f| f.puts(text) }

    self
  end

  params = ARGV.getopts(
      'h:',
      'launch-template:',
      'name-tag:',
      'security-group:',
      'subnet:',
      'target-group:',
      'availability-zone:',
      'instance-type:',
      'delim:',
      'state:',
      'launch',
      'role:',
      'rotate',
      'list',
      'debug',
  )

  target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
  target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)

  if params['launch']
    Launch = ::Egotter::Launch
    Install = ::Egotter::Install

    if params['role'] == 'web'
      az = target_group.availability_zone_with_fewest_instances
      server = Launch::Web.new(Launch::Params.new(params.merge('availability-zone' => az))).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      Install::Web.new(server.id, server.host).install

      target_group.register(server.id)

      if params['rotate']
        instance = target_group.oldest_instance
        target_group.deregister(instance.id)
        instance.terminate
      end
    elsif params['role'] == 'sidekiq'
      az = 'ap-northeast-1b'
      server = Launch::Sidekiq.new(Launch::Params.new(params.merge('availability-zone' => az))).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      Install::Sidekiq.new(server.id, server.host).install
    else
      raise "Invalid role #{params['role']}"
    end

    %x(git tag deploy-#{server.name})
    %x(git push origin --tags)
  elsif params['list']
    state = params['state'].to_s.empty? ? 'healthy' : params['state']
    puts target_group.instances(state: state).map(&:name).join(params['delim'] || ' ')
  elsif params['debug']
  end
end
