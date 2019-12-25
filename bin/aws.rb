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
require_relative '../lib/egotter/uninstall'

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
      'instance-id:',
      'instance-name:',
      'delim:',
      'state:',
      'launch',
      'terminate',
      'sync',
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
        aws.rb --sync --role web --instance-id i-0000
        aws.rb --sync --role sidekiq --instance-id i-0000
        aws.rb --list
        aws.rb --terminate --role web
        aws.rb --terminate --role sidekiq --instance-id i-0000
    TEXT

    exit
  end

  module Launcher
    def build(params)
      role = params['role']

      if role == 'web'
        Web.new(params)
      elsif role == 'sidekiq'
        Sidekiq.new(params)
      else
        raise "Invalid role #{role}"
      end
    end

    module_function :build

    class Base
      def initialize
        @role = nil
        @launched = nil
        @terminated = nil
      end

      def launch
        after_launch if @launched
        after_terminate if @terminated
      end

      def after_launch
        CloudWatchClient::Dashboard.new('egotter-linux-system').
            append_cpu_utilization(@role, @launched.id).
            append_memory_utilization(@role, @launched.id).
            append_cpu_credit_balance(@role, @launched.id).
            append_disk_space_utilization(@role, @launched.id).
            update
      end

      def after_terminate
        CloudWatchClient::Dashboard.new('egotter-linux-system').
            remove_cpu_utilization(@role, @terminated.id).
            remove_memory_utilization(@role, @terminated.id).
            remove_cpu_credit_balance(@role, @terminated.id).
            remove_disk_space_utilization(@role, @terminated.id).
            update
      end
    end

    class Web < Base
      def initialize(params)
        super()
        @params = params
        @role = params['role']

        target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
        @target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)
      end

      def launch
        az = @target_group.availability_zone_with_fewest_instances
        params = ::Egotter::Launch::Params.new(@params.merge('availability-zone' => az))
        server = ::Egotter::Launch::Web.new(params).launch
        append_to_ssh_config(server.id, server.host, server.public_ip)
        ::Egotter::Install::Web.new(server.id).install

        @target_group.register(server.id)
        @launched = server

        if @params['rotate']
          instance = @target_group.oldest_instance
          if instance && @target_group.deregister(instance.id)
            instance.terminate
            @terminated = instance
          end
        end

        super

        @launched
      end
    end

    class Sidekiq < Base
      def initialize(params)
        super()
        @params = params
        @role = params['role']
      end

      def launch
        az = 'ap-northeast-1b'
        params = ::Egotter::Launch::Params.new(@params.merge('availability-zone' => az))
        server = ::Egotter::Launch::Sidekiq.new(params).launch
        append_to_ssh_config(server.id, server.host, server.public_ip)
        ::Egotter::Install::Sidekiq.new(server.id).install

        @launched = server

        super

        @launched
      end
    end
  end

  module Terminator
    def build(params)
      role = params['role']

      if role == 'web'
        Web.new(params)
      elsif role == 'sidekiq'
        Sidekiq.new(params)
      else
        raise "Invalid role #{role}"
      end
    end

    module_function :build

    class Base
      def initialize
        @role = nil
        @terminated = nil
      end

      def terminate
        after_terminate if @terminated
      end

      def after_terminate
        CloudWatchClient::Dashboard.new('egotter-linux-system').
            remove_cpu_utilization(@role, @terminated.id).
            remove_memory_utilization(@role, @terminated.id).
            remove_cpu_credit_balance(@role, @terminated.id).
            remove_disk_space_utilization(@role, @terminated.id).
            update
      end
    end

    class Web < Base
      def initialize(params)
        super()
        @role = params['role']

        target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
        @target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)
      end

      def terminate
        instance = @target_group.oldest_instance
        if instance && @target_group.deregister(instance.id)
          instance.terminate
          @terminated = instance
        end

        super

        @terminated
      end
    end

    class Sidekiq < Base
      def initialize(params)
        super()
        @params = params
        @role = params['role']
      end

      def terminate
        instance = ::Egotter::Aws::Instance.retrieve_by(id: @params['instance-id'], name: @params['instance-name'])
        if instance
          ::Egotter::Uninstall::Sidekiq.new(instance.id).uninstall
          instance.terminate
          @terminated = instance
        end

        super

        @terminated
      end
    end
  end

  if params['launch']
    launcher = Launcher.build(params)
    instance = launcher.launch

    %x(git tag deploy-#{instance.name})
    %x(git push origin --tags)

  elsif params['terminate']
    terminator = Terminator.build(params)
    terminator.terminate

  elsif params['sync']
    if params['role'] == 'web'
      ::Egotter::Install::Web.new(params['instance-id']).sync
    elsif params['role'] == 'sidekiq'
      ::Egotter::Install::Sidekiq.new(params['instance-id']).sync
    else
      raise "Invalid role #{params['role']}"
    end
  elsif params['list']
    state = params['state'].to_s.empty? ? 'healthy' : params['state']
    delim = params['delim'] || ' '

    target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
    puts ::Egotter::Aws::TargetGroup.new(target_group_arn).instances(state: state).map(&:name).join(delim)
  elsif params['debug']
  end
end
