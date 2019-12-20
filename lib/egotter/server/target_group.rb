module Egotter
  module Server
    class TargetGroup
      def initialize(arn)
        @arn = arn
      end

      def register(instance_id)
        previous_count = list_instances.size

        params = {
            target_group_arn: @arn,
            targets: [{id: instance_id}]
        }
        puts params.inspect
        client.register_targets(params)
        wait_until(:target_in_service, params)

        AwsUtil.green "Current targets count is #{list_instances.size} (was #{previous_count})"

        self
      end

      def deregister(instance_id)
        previous_count = list_instances.size

        params = {
            target_group_arn: @arn,
            targets: [{id: instance_id}]
        }
        puts params.inspect
        client.deregister_targets(params)
        wait_until(:target_deregistered, params)

        AwsUtil.green "Current targets count is #{list_instances.size} (was #{previous_count})"

        self
      end

      def list_instances(state: 'healthy')
        params = {target_group_arn: @arn}

        client.describe_target_health(params).
            target_health_descriptions.
            select { |d| d.target_health.state == state }.map do |description|
          Instance.retrieve(description.target.id)
        end
      end

      private

      def wait_until(name, params)
        instance_id = params[:targets][0][:id]

        client.wait_until(name, params) do |w|
          w.before_wait do |n, resp|
            puts "waiting for #{name} #{instance_id}"
          end
        end
      rescue Aws::Waiters::Errors::WaiterFailed => e
        puts "failed waiting for #{name}: #{e.message}"
        exit
      end

      def client
        @client ||= Aws::ElasticLoadBalancingV2::Client.new(region: 'ap-northeast-1')
      end
    end
  end
end