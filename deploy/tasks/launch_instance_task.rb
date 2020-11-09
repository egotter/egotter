require_relative '../lib/deploy_ruby/aws/ec2'
require_relative '../lib/deploy_ruby/aws/instance'

module Tasks
  module LaunchInstanceTask
    class Base
      def initialize(params)
        @params = params
        @launch_params = LaunchParams.new(params)
        @index = params.delete('instance-index')
      end

      def launch
        id = ::DeployRuby::Aws::EC2.new.launch_instance(name, @launch_params, @params)
        ::DeployRuby::Aws::Instance.retrieve(id)
      end

      private

      def name_suffix
        @index ? "_#{@index}" : ''
      end
    end

    class Web < Base
      def name
        @name ||= "egotter_web#{Time.now.strftime('%m%d%H%M')}#{name_suffix}"
      end
    end

    class Sidekiq < Base
      def name
        @name ||= "egotter_sidekiq#{Time.now.strftime('%m%d%H%M')}#{name_suffix}"
      end
    end

    class Plain < Base
      def name
        @name ||= "egotter_plain#{Time.now.strftime('%m%d%H%M')}#{name_suffix}"
      end
    end

    class LaunchParams < ::Hash
      def initialize(params)
        self[:launch_template] = {launch_template_id: params['launch-template'] || ENV['AWS_LAUNCH_TEMPLATE']}
        self[:min_count] = 1
        self[:max_count] = 1
        self[:security_group_ids] = [params['security-group'] || ENV['AWS_SECURITY_GROUP']]
        self[:subnet_id] = pick_subnet(params)

        if params['instance-type']
          self[:instance_type] = params['instance-type']
        end
      end

      private

      def pick_subnet(params)
        params['availability-zone'] ? az_to_subnet(params['availability-zone']) : ENV['AWS_SUBNET']
      end

      def az_to_subnet(az)
        case az
        when 'ap-northeast-1b' then ENV['AWS_SUBNET_1B']
        when 'ap-northeast-1c' then ENV['AWS_SUBNET_1C']
        when 'ap-northeast-1d' then ENV['AWS_SUBNET_1D']
        end
      end
    end
  end
end