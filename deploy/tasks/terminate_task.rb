require_relative '../../app/models/cloud_watch_client'

require_relative './uninstall_task'

module Tasks
  module TerminateTask
    def build(params)
      role = params['role']

      if role == 'auto'
        role = auto_detect_role(params)
        params['role'] = role
      end

      if role == 'web'
        WebTask.new(params)
      elsif role == 'sidekiq' || role == 'sidekiq_prompt_reports'
        SidekiqTask.new(params)
      elsif role == 'plain'
        PlainTask.new(params)
      else
        raise "Invalid role #{role}"
      end
    end

    module_function :build

    def auto_detect_role(params)
      name = params['instance-name']

      if name.to_s.include?('_web')
        'web'
      elsif name.to_s.include?('_sidekiq')
        'sidekiq'
      elsif name.to_s.include?('_plain')
        'plain'
      else
        raise 'role is auto, but collect role is not found'
      end
    end

    module_function :auto_detect_role

    class Task
      attr_reader :action, :instance

      def initialize
        @action = :terminate
        @instance = nil
        @role = nil
        @terminated = nil
      end

      def run
        after_terminate if @terminated && %w(web sidekiq sidekiq_prompt_reports).include?(@role)
      end

      def after_terminate
        CloudWatchClient::Dashboard.new('egotter-linux-system').
            remove_cpu_utilization(@role, @terminated.id).
            remove_memory_utilization(@role, @terminated.id).
            remove_cpu_credit_balance(@role, @terminated.id).
            remove_disk_space_utilization(@role, @terminated.id).
            update
      end

      def logger
        DeployRuby.logger
      end
    end

    class WebTask < Task
      def initialize(params)
        super()
        @role = params['role']

        @target_group = ::DeployRuby::Aws::TargetGroup.new(params['target-group'])
      end

      def run
        instance = @target_group.oldest_instance
        if instance && @target_group.deregister(instance.id)
          Tasks::UninstallTask::Web.new(instance.id).uninstall
          instance.terminate
          @instance = @terminated = instance
        end

        super
      end
    end

    class SidekiqTask < Task
      def initialize(params)
        super()
        @params = params
        @role = params['role']
      end

      def run
        instance = ::DeployRuby::Aws::Instance.retrieve_by(id: @params['instance-id'], name: @params['instance-name'], name_regexp: @params['instance-name-regexp'])
        if instance
          Tasks::UninstallTask::Sidekiq.new(instance.id).uninstall
          instance.terminate
          @instance = @terminated = instance
        end

        super
      end
    end

    class PlainTask < Task
      def initialize(params)
        super()
        @params = params
        @role = params['role']
      end

      def run
        instance = ::DeployRuby::Aws::Instance.retrieve_by(id: @params['instance-id'], name: @params['instance-name'])
        if instance
          instance.terminate
          @instance = @terminated = instance
        end

        super
      end
    end
  end
end
