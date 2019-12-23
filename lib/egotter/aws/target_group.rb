require_relative './instance'

module Egotter
  module Aws
    class TargetGroup
      def initialize(arn)
        @arn = arn
      end

      def register(instance_id)
        previous_count = instances.size

        params = {
            target_group_arn: @arn,
            targets: [{id: instance_id}]
        }
        puts params.inspect
        client.register_targets(params)
        wait_until(:target_in_service, params)

        green "Current targets count is #{instances.size} (was #{previous_count})"

        self
      end

      def deregister(instance_id)
        previous_count = instances.size

        params = {
            target_group_arn: @arn,
            targets: [{id: instance_id}]
        }
        puts params.inspect
        client.deregister_targets(params)
        wait_until(:target_deregistered, params)

        green "Current targets count is #{instances.size} (was #{previous_count})"

        self
      end

      def instances(state: 'healthy')
        params = {target_group_arn: @arn}

        client.describe_target_health(params).
            target_health_descriptions.
            select { |d| d.target_health.state == state }.map do |description|
          ::Egotter::Aws::Instance.retrieve(description.target.id)
        end
      end

      def oldest_instance
        id = instances.sort_by(&:launched_at).first.id
        ::Egotter::Aws::Instance.retrieve(id)
      end

      def availability_zone_with_fewest_instances
        count = {
            'ap-northeast-1b' => 0,
            'ap-northeast-1c' => 0,
            'ap-northeast-1d' => 0,
        }
        instances.each { |i| count[i.availability_zone] += 1 }
        count.sort_by { |k, v| v }[0][0]
      end

      private

      def wait_until(name, params)
        instance_id = params[:targets][0][:id]

        client.wait_until(name, params) do |w|
          w.before_wait do |n, resp|
            puts "waiting for #{name} #{instance_id}"
          end
        end
      rescue ::Aws::Waiters::Errors::WaiterFailed => e
        puts "failed waiting for #{name}: #{e.message}"
        exit
      end

      def client
        @client ||= ::Aws::ElasticLoadBalancingV2::Client.new(region: 'ap-northeast-1')
      end

      def green(str)
        puts "\e[32m#{str}\e[0m"
      end
    end
  end
end