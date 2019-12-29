module Tasks
  module LaunchTask
    class Params < ::Hash
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

    class Task < ::DeployRuby::Task
      def initialize(params)
        @params = params
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
  end

end