#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'
require 'base64'
require 'erb'

require_relative '../app/models/cloud_watch_client'

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
      'h',
      'help',
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
      'terminate',
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
          aws.rb --launch --role sidekiq --instance-type m5.large
          aws.rb --list
          aws.rb --terminate --role web
    TEXT

    exit
  end

  target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
  target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)

  if params['launch']
    Launch = ::Egotter::Launch
    Install = ::Egotter::Install

    role = params['role']

    if role == 'web'
      az = target_group.availability_zone_with_fewest_instances
      server = Launch::Web.new(Launch::Params.new(params.merge('availability-zone' => az))).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      Install::Web.new(server.id, server.host).install

      target_group.register(server.id)

      if params['rotate']
        instance = target_group.oldest_instance
        if instance && target_group.deregister(instance.id)
          instance.terminate
        end
      end
    elsif role == 'sidekiq'
      az = 'ap-northeast-1b'
      server = Launch::Sidekiq.new(Launch::Params.new(params.merge('availability-zone' => az))).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      Install::Sidekiq.new(server.id, server.host).install
    else
      raise "Invalid role #{role}"
    end

    CloudWatchClient::Dashboard.new('egotter-linux-system').
        append_cpu_utilization(role, server.id).
        append_memory_utilization(role, server.id).
        append_cpu_credit_balance(role, server.id).
        append_disk_space_utilization(role, server.id).
        update

    %x(git tag deploy-#{server.name})
    %x(git push origin --tags)
  elsif params['terminate']
    role = params['role']
    terminated = false

    if role == 'web'
      instance = target_group.oldest_instance
      if instance && target_group.deregister(instance.id)
        instance.terminate
        terminated = true
      end
    else
      raise "Invalid role #{role}"
    end

    if terminated
      CloudWatchClient::Dashboard.new('egotter-linux-system').
          remove_cpu_utilization(role, instance.id).
          remove_memory_utilization(role, instance.id).
          remove_cpu_credit_balance(role, instance.id).
          remove_disk_space_utilization(role, instance.id).
          update
    end
  elsif params['list']
    state = params['state'].to_s.empty? ? 'healthy' : params['state']
    puts target_group.instances(state: state).map(&:name).join(params['delim'] || ' ')
  elsif params['debug']
  end
end
