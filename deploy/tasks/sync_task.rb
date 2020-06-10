require_relative './install_task'

module Tasks
  module SyncTask
    def build(params)
      role = params['role']

      if role == 'web'
        WebTask.new(params)
      elsif role == 'sidekiq'
        SidekiqTask.new(params)
      else
        raise "Invalid role #{role}"
      end
    end

    module_function :build

    class Task
      attr_reader :action, :instance

      def initialize
        @action = :sync
        @instance = nil
      end

      def logger
        DeployRuby.logger
      end
    end

    class WebTask < Task
      def initialize(params)
        @instance_id = params['instance-id']
      end

      def run
        task = Tasks::InstallTask::Web.new(@instance_id)
        task.sync
        @instance = task.instance
      end
    end

    class SidekiqTask < Task
      def initialize(params)
        @instance_id = params['instance-id']
      end

      def run
        task = Tasks::InstallTask::Sidekiq.new(@instance_id)
        task.sync
        @instance = task.instance
      end
    end
  end
end
