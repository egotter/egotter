require_relative '../../app/models/cloud_watch_client'

require_relative './launch_instance_task'
require_relative './install_task'
require_relative './uninstall_task'

module Tasks
  module LaunchTask
    def build(params)
      role = params['role']

      case role
      when 'web'
        LaunchWebTask.new(params)
      when 'sidekiq'
        LaunchSidekiqTask.new(params)
      when 'sidekiq_prompt_reports'
        LaunchSidekiqPromptReportsTask.new(params)
      when 'plain'
        LaunchPlainTask.new(params)
      else
        raise "Invalid role params=#{params.inspect}"
      end
    end

    module_function :build

    class Base < ::DeployRuby::Task
      attr_reader :action, :instance

      def initialize
        @action = :launch
        @instance = nil
        @role = nil
        @launched = nil
        @terminated = nil
      end

      def run
        after_launch if @launched
        after_terminate if @terminated
      end

      private

      def after_launch
        return if @role == 'plain'

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

      def append_to_ssh_config(id, host, public_ip)
        text = <<~"TEXT"
          # #{id}
          Host #{host}
            HostName     #{public_ip}
            IdentityFile ~/.ssh/egotter.pem
            User         ec2-user
        TEXT

        logger.info text
        File.open('./ssh_config', 'a') { |f| f.puts(text) }
      end
    end
  end

  class LaunchWebTask < LaunchTask::Base
    def initialize(params)
      super()
      @params = params
      @role = params['role']

      target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
      @target_group = ::DeployRuby::Aws::TargetGroup.new(target_group_arn)
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
      @instance = @launched = @server

      if @params['rotate']
        instance = @target_group.oldest_instance
        if instance && @target_group.deregister(instance.id)
          Tasks::UninstallTask::Web.new(instance.id).uninstall
          instance.terminate
          @terminated = instance
        end
      end

      super
    end
  end

  class LaunchSidekiqTask < LaunchTask::Base
    def initialize(params)
      super()
      @params = params
      @role = params['role']
    end

    def run
      az = 'ap-northeast-1b'
      server = Tasks::LaunchInstanceTask::Sidekiq.new(@params.merge('availability-zone' => az)).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      Tasks::InstallTask::Sidekiq.new(server.id).install

      @instance = @launched = server

      super
    end
  end

  class LaunchSidekiqPromptReportsTask < LaunchTask::Base
    def initialize(params)
      super()
      @params = params
      @role = params['role']
    end

    def run
      az = 'ap-northeast-1b'
      server = Tasks::LaunchInstanceTask::Sidekiq.new(@params.merge('availability-zone' => az)).launch
      append_to_ssh_config(server.id, server.host, server.public_ip)
      Tasks::InstallTask::SidekiqPromptReports.new(server.id).install

      @instance = @launched = server

      super
    end
  end

  class LaunchPlainTask < LaunchTask::Base
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

      @instance = @launched = @server

      super
    end
  end
end
