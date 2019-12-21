module Egotter
  module Server
    module Ec2Util
      module_function

      def launch_instance(template:, security_group:, subnet:, name:)
        params = {
            launch_template: {launch_template_id: template},
            min_count: 1,
            max_count: 1,
            security_group_ids: [security_group],
            subnet_id: subnet
        }

        instance = resource.create_instances(params).first
        wait_until(instance.id, :instance_running)
        wait_until(instance.id, :instance_status_ok)

        instance.create_tags(tags: [{key: 'Name', value: name}])
        instance.id
      rescue => e
        if defined?(instance) && instance
          terminate_instance(instance.id)
        end
        raise
      end

      def terminate_instance(id)
        resource.client.terminate_instances({instance_ids: [id]})
        wait_until(id, :instance_terminated)
        id
      end

      def retrieve_instance(id)
        instance = nil
        filters = [name: 'instance-id', values: [id]]
        resource.instances(filters: filters).each do |i|
          instance = i
          break
        end
        instance
      end

      def wait_until(id, state)
        resource.client.wait_until(state, instance_ids: [id]) do |w|
          w.before_wait do |n, resp|
            puts "waiting for #{state} #{id}"
          end
        end
      rescue Aws::Waiters::Errors::WaiterFailed => e
        puts "failed waiting for #{state}: #{e.message}"
        exit
      end

      def resource
        @resource ||= Aws::EC2::Resource.new(region: 'ap-northeast-1')
      end
    end
  end
end