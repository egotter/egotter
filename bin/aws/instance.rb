#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'
require 'base64'
require 'erb'

require_relative '../../lib/secret_file'

require_relative '../../lib/egotter/server/target_group'
require_relative '../../lib/egotter/server/launcher'
require_relative '../../lib/egotter/server/installer'

STDOUT.sync = true

if __FILE__ == $0
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
      'rotate',
      'create',
      'create-sidekiq',
      'list',
      'debug',
  )

  target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
  target_group = ::Egotter::Server::TargetGroup.new(target_group_arn)

  availability_zone =
      if params['create-sidekiq']
        'ap-northeast-1b'
      elsif params['create']
        target_group.availability_zone_with_fewest_instances
      end
  params['availability-zone'] = availability_zone

  Launcher = ::Egotter::Server::Launcher
  Installer = ::Egotter::Server::Installer

  if params['create-sidekiq']
    launch_params = Launcher::Params.new(params)
    server = Launcher::Sidekiq.new(launch_params).launch
    Installer::Sidekiq.new(server.name, id: server.id, public_ip: server.public_ip).install

    %x(git tag deploy-sidekiq-#{server.name}-#{Time.now.to_i})
    %x(git push origin --tags)

  elsif params['create']
    launch_params = Launcher::Params.new(params)
    server = Launcher::Web.new(launch_params).launch
    Installer::Web.new(server.name, id: server.id, public_ip: server.public_ip).install

    target_group.register(server.id)

    if params['rotate']
      instance = target_group.oldest_instance
      target_group.deregister(instance.id)
      instance.terminate
    end

    %x(git tag deploy-web-#{server.name}-#{Time.now.to_i})
    %x(git push origin --tags)

  elsif params['list']
    state = params['state'].to_s.empty? ? 'healthy' : params['state']
    puts target_group.instances(state: state).map(&:name).join(params['delim'] || ' ')
  elsif params['debug']
  end
end
