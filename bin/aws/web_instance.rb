#!/usr/bin/env ruby

require 'dotenv/load'

require 'optparse'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancingv2'
require 'base64'
require 'erb'

require_relative '../../lib/secret_file'
require_relative '../../lib/egotter/server/aws_util'
require_relative '../../lib/egotter/server/instance'
require_relative '../../lib/egotter/server/target_group'
require_relative '../../lib/egotter/server/util'
require_relative '../../lib/egotter/server/web'

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
      'delim:',
      'state:',
      'rotate',
      'create',
      'list',
      'debug',
  )

  target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
  target_group = ::Egotter::Server::TargetGroup.new(target_group_arn)

  if params['create']
    az = params['availability-zone'].to_s.empty? ?
             ::Egotter::Server::AwsUtil.assign_availability_zone(target_group_arn) : params['availability-zone']
    subnet = ::Egotter::Server::AwsUtil.az_to_subnet(az)

    values = {
        template: params['launch-template'] || ENV['AWS_LAUNCH_TEMPLATE'],
        security_group: params['security-group'] || ENV['AWS_SECURITY_GROUP'],
        name: params['name-tag'].to_s.empty? ? ::Egotter::Server::AwsUtil.generate_name : params['name-tag'],
        subnet: subnet || ENV['AWS_SUBNET']
    }
    puts values.inspect

    server = ::Egotter::Server::Web.new(values).start
    target_group.register(server.id)

    if params['rotate']
      instance = target_group.list_instances.sort_by { |i| i.launched_at }.first
      target_group.deregister(instance.id)
      ::Egotter::Server::Web.new(id: instance.id).terminate
    end

    %x(git tag deploy-web-#{server.name}-#{Time.now.to_i})
    %x(git push origin --tags)

  elsif params['list']
    state = params['state'].to_s.empty? ? 'healthy' : params['state']
    puts target_group.list_instances(state: state).map(&:name).join(params['delim'] || ' ')
  elsif params['debug']
  end
end
