module DeployRuby
  module Aws
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
  end
end