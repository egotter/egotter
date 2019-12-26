require_relative '../tasks/install'

module Taskbooks
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
      attr_reader :kind, :instance

      def initialize
        @kind = :sync
        @instance = nil
      end
    end

    class WebTask < Task
      def initialize(params)
        @instance_id = params['instance-id']
      end

      def run
        task = ::Egotter::Install::Web.new(@instance_id)
        task.sync
        @instance = task.instance
      end
    end

    class SidekiqTask < Task
      def initialize(params)
        @instance_id = params['instance-id']
      end

      def run
        task = ::Egotter::Install::Sidekiq.new(@instance_id)
        task.sync
        @instance = task.instance
      end
    end
  end
end
