module DeployRuby
  module Aws
    module EC2
      module_function

      def launch_instance(name, params)
        instance = resource.create_instances(params).first
        wait_until(instance.id, :instance_running)
        wait_until(instance.id, :instance_status_ok)

        instance = retrieve_instance(instance.id)
        test_ssh_connection(instance.public_ip_address)

        instance.create_tags(tags: [{key: 'Name', value: name}])
        instance.id
      rescue ::Aws::EC2::Errors::InvalidParameterCombination => e
        red "Invalid params #{params.inspect}"
        raise
      rescue Interrupt, StandardError => e
        red "#{e.class} is raised and terminates already started instance."
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

      def retrieve_instance_by(name:)
        instance = nil
        filters = [name: 'tag:Name', values: [name]]
        resource.instances(filters: filters).each do |i|
          instance = i
          break
        end
        instance
      end

      def retrieve_instances
        resource.instances
      end

      def test_ssh_connection(public_ip)
        cmd = "ssh -q -i ~/.ssh/egotter.pem ec2-user@#{public_ip} exit"
        30.times do |n|
          logger.info "waiting for test_ssh_connection #{public_ip}"
          if system(cmd, exception: false)
            break
          else
            sleep 5
          end
          raise if n == 29
        end
      end

      def wait_until(id, state)
        resource.client.wait_until(state, instance_ids: [id]) do |w|
          w.before_wait do |n, resp|
            logger.info "waiting for #{state} #{id}"
          end
        end
      rescue ::Aws::Waiters::Errors::WaiterFailed => e
        red "failed waiting for #{state}: #{e.message}"
        exit
      end

      def resource
        @resource ||= ::Aws::EC2::Resource.new(region: 'ap-northeast-1')
      end

      def green(str)
        logger.info "\e[32m#{str}\e[0m"
      end

      def red(str)
        logger.info "\e[31m#{str}\e[0m"
      end

      def logger
        DeployRuby.logger
      end
    end
  end
end