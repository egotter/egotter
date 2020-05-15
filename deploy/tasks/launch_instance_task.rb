require_relative '../lib/deploy_ruby/task'
require_relative '../lib/deploy_ruby/aws/params'
require_relative '../lib/deploy_ruby/aws/ec2'
require_relative '../lib/deploy_ruby/aws/instance'

module Tasks
  module LaunchInstanceTask
    class Task < ::DeployRuby::Task
      def initialize(params)
        @params = ::DeployRuby::Aws::Params.new(params)
      end

      def name
        raise NotImplementedError
      end

      def launch
        id = ::DeployRuby::Aws::EC2.launch_instance(name, @params)
        ::DeployRuby::Aws::Instance.retrieve(id)
      end
    end

    class Web < Task
      def name
        @name || "egotter_web#{Time.now.strftime('%m%d%H%M')}"
      end
    end

    class Sidekiq < Task
      def name
        @name ||= "egotter_sidekiq#{Time.now.strftime('%m%d%H%M')}"
      end
    end

    class Plain < Task
      def name
        @name ||= "egotter_plain#{Time.now.strftime('%m%d%H%M')}"
      end
    end
  end
end