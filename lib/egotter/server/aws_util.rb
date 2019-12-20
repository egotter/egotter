module Egotter
  module Server
    module AwsUtil
      module_function

      def green(str)
        puts "\e[32m#{str}\e[0m"
      end

      def generate_name
        "egotter_web#{Time.now.strftime('%m%d%H%M')}"
      end

      def az_to_subnet(az)
        case az
        when 'ap-northeast-1b' then ENV['AWS_SUBNET_1B']
        when 'ap-northeast-1c' then ENV['AWS_SUBNET_1C']
        when 'ap-northeast-1d' then ENV['AWS_SUBNET_1D']
        end
      end

      def assign_availability_zone(target_group)
        count = {
            'ap-northeast-1b' => 0,
            'ap-northeast-1c' => 0,
            'ap-northeast-1d' => 0,
        }
        TargetGroup.new(target_group).list_instances.each { |i| count[i.availability_zone] += 1 }
        count.sort_by { |k, v| v }[0][0]
      end
    end
  end
end