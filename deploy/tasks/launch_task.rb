require 'date'

require_relative '../lib/deploy/logger'
require_relative './launch_instance_task'
require_relative './install_task'
require_relative './uninstall_task'

module Tasks
  module LaunchTask
    def build(params)
      role = params['role']

      case role
      when 'web'
        Web.new(params)
      when 'sidekiq'
        Sidekiq.new(params)
      when 'plain'
        Plain.new(params)
      else
        raise UnknownRoleError, "params=#{params.inspect}"
      end
    end

    module_function :build

    class UnknownRoleError < RuntimeError; end

    class Base
      attr_reader :action, :instance

      def initialize
        @action = :launch
        @instance = nil
        @role = nil
      end

      private

      def add_to_dashboard(role, instance_id)
        Dashboard.new('egotter-linux-system').append_all(role, instance_id).update
      end

      def remove_from_dashboard(role, instance_id)
        Dashboard.new('egotter-linux-system').remove_all(role, instance_id).update
      end

      def append_to_ssh_config(id, host, public_ip)
        text = <<~"TEXT"
          # #{Date.today} #{id}
          Host #{host}
            HostName     #{public_ip}
            IdentityFile ~/.ssh/egotter.pem
            User         ec2-user
        TEXT

        logger.info text
        File.open('./ssh_config', 'a') { |f| f.puts(text) }
      end

      def logger
        Deploy.logger
      end
    end

    class Web < Base
      def initialize(params)
        super()
        @params = params
        @role = params['role']

        @target_group = ::Deploy::Aws::TargetGroup.new(params['target-group'])
      end

      def launch_instance(index = nil)
        az = @target_group.availability_zone_with_fewest_instances
        params = @params.merge('availability-zone' => az, 'instance-index' => index)
        @server = Tasks::LaunchInstanceTask::Web.new(params).launch
      end

      def run
        if @server.nil?
          launch_instance
        end

        append_to_ssh_config(@server.id, @server.host, @server.public_ip)
        Tasks::InstallTask::Web.new(@server.id).install

        @target_group.register(@server.id)
        @instance = @server

        if @params['rotate']
          instance = @target_group.oldest_instance
          if instance && @target_group.deregister(instance.id)
            Tasks::UninstallTask::Web.new(instance.id).uninstall
            instance.terminate
            remove_from_dashboard(@role, instance.id)
          end
        end

        add_to_dashboard(@role, @server.id)
      end
    end

    class Sidekiq < Base
      def initialize(params)
        super()
        @params = params
        @role = params['role']
      end

      def launch_instance(index = nil)
        az = 'ap-northeast-1b'
        params = @params.merge('availability-zone' => az, 'instance-index' => index)
        @server = Tasks::LaunchInstanceTask::Sidekiq.new(params).launch
      end

      def run
        if @server.nil?
          launch_instance
        end

        append_to_ssh_config(@server.id, @server.host, @server.public_ip)
        Tasks::InstallTask::Sidekiq.new(@server.id).install

        @instance = @server
        add_to_dashboard(@role, @server.id)
      end
    end

    class Plain < Base
      def initialize(params)
        super()
        @params = params
        @role = params['role']
      end

      def launch_instance(index = nil)
        az = 'ap-northeast-1b'
        params = @params.merge('availability-zone' => az, 'instance-index' => index)
        @server = Tasks::LaunchInstanceTask::Plain.new(params).launch
      end

      def run
        if @server.nil?
          launch_instance
        end

        append_to_ssh_config(@server.id, @server.host, @server.public_ip)
        Tasks::InstallTask::Plain.new(@server.id).install

        @instance = @server
      end
    end
  end
end
