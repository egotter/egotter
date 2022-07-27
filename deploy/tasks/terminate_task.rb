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
      elsif role == 'sidekiq'
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
      end

      def run
        raise NotImplementedError
      end

      def update_dashboard(instance)
        Dashboard.new('egotter-linux-system').
            remove_all(@role, instance.id).
            update
      end

      def upload_logs(instance)
        LogUploader.new(instance.name).with_ssh.
            add('log/production.log').
            add('log/puma.log').
            add('log/sidekiq.log').
            add('log/sidekiq_misc.log').
            add('log/airbag.log').
            add('log/cron.log').
            upload
      end

      def logger
        Deploy.logger
      end
    end

    class WebTask < Task
      def initialize(params)
        super()
        @params = params
        @role = params['role']

        @target_group = ::Deploy::Aws::TargetGroup.new(params['target-group'])
      end

      def run
        if @params['instance-id'] || @params['instance-name'] || @params['instance-name-regexp']
          instance = ::Deploy::Aws::Instance.retrieve_by(id: @params['instance-id'], name: @params['instance-name'], name_regexp: @params['instance-name-regexp'])
        else
          instance = @target_group.oldest_instance
        end

        if instance.api_termination_disabled?
          raise "Cannot terminate an instance with :disable_api_termination set to true instance_id=#{instance.id}"
        end

        if instance && @target_group.deregister(instance.id)
          Tasks::UninstallTask::Web.new(instance.id).uninstall
          upload_logs(instance)
          update_dashboard(instance)
          instance.terminate
          @instance = instance
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
        if @params['instance-id'] || @params['instance-name'] || @params['instance-name-regexp']
          instance = ::Deploy::Aws::Instance.retrieve_by(id: @params['instance-id'], name: @params['instance-name'], name_regexp: @params['instance-name-regexp'])
        else
          instance = ::Deploy::Aws::Instance.retrieve_by(name_regexp: 'egotter_sidekiq\\d{8}')
        end

        if instance.api_termination_disabled?
          raise "Cannot terminate an instance with :disable_api_termination set to true instance_id=#{instance.id}"
        end

        if instance
          Tasks::UninstallTask::Sidekiq.new(instance.id).uninstall
          upload_logs(instance)
          update_dashboard(instance)
          instance.terminate
          @instance = instance
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
        instance = ::Deploy::Aws::Instance.retrieve_by(id: @params['instance-id'], name: @params['instance-name'])

        if instance
          instance.terminate
          @instance = instance
        end

        super
      end
    end
  end
end
