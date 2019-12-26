require_relative '../lib/aws'

module Taskbooks
  module ListTask
    def build(params)
      role = params['role']

      if role == 'web'
        WebTask.new(params)
      else
        raise "Invalid role #{role}"
      end
    end

    module_function :build

    class Task
      attr_reader :kind

      def initialize
        @kind = :list
      end
    end

    class WebTask < Task
      def initialize(params)
        @state = params['state'].to_s.empty? ? 'healthy' : params['state']
        @delim = params['delim'] || ' '

        target_group_arn = params['target-group'] || ENV['AWS_TARGET_GROUP']
        @target_group = ::Egotter::Aws::TargetGroup.new(target_group_arn)
      end

      def run
        puts @target_group.instances(state: @state).map(&:name).join(@delim)
      end
    end
  end
end
