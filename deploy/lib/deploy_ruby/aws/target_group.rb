require_relative './instance'

module DeployRuby
  module Aws
    class TargetGroup
      def initialize(arn)
        @arn = arn || ENV['AWS_TARGET_GROUP']
      end

      def register(instance_id)
        previous_count = registered_instances.size

        params = {
            target_group_arn: @arn,
            targets: [{id: instance_id}]
        }

        client.register_targets(params)
        wait_until(:target_in_service, params)

        success "Current targets count is #{registered_instances.size} (was #{previous_count})"

        self
      end

      def deregister(instance_id)
        previous_count = registered_instances.size
        if previous_count < 2
          failure 'Cannot deregister as instances size is less than 2'
          exit
        end

        params = {
            target_group_arn: @arn,
            targets: [{id: instance_id}]
        }

        client.deregister_targets(params)
        wait_until(:target_deregistered, params)

        success "Current targets count is #{registered_instances.size} (was #{previous_count})"

        true
      end

      def registered_instances(state: 'healthy')
        params = {target_group_arn: @arn}

        client.describe_target_health(params).
            target_health_descriptions.
            select { |d| d.target_health.state == state }.map do |description|
          Instance.retrieve(description.target.id)
        end
      end

      def oldest_instance
        id = registered_instances.sort_by(&:launched_at).first.id
        Instance.retrieve(id)
      end

      def availability_zone_with_fewest_instances
        count = Hash.new(0)
        registered_instances.each { |i| count[i.availability_zone] += 1 }
        count.sort_by { |k, v| v }[0][0]
      end

      private

      def wait_until(name, params)
        instance_id = params[:targets][0][:id]

        client.wait_until(name, params) do |w|
          w.before_wait do |n, resp|
            logger.info "waiting for #{name} #{instance_id}"
          end
        end
      rescue ::Aws::Waiters::Errors::WaiterFailed => e
        failure "failed waiting for #{name}: #{e.message}"
        exit
      end

      def client
        @client ||= ::Aws::ElasticLoadBalancingV2::Client.new(region: 'ap-northeast-1')
      end

      def success(str)
        logger.info "\e[33m#{str}\e[0m"
      end

      def failure(str)
        logger.info "\e[31m#{str}\e[0m"
      end

      def logger
        DeployRuby.logger
      end
    end
  end
end