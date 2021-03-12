require_relative './ec2'

module Deploy
  module Aws
    class Instance
      attr_reader :id, :name, :public_ip, :availability_zone, :launched_at, :instance_type

      def initialize(instance)
        @instance = instance
        @id = instance.id
        @name = instance.tags.find { |t| t.key == 'Name' }&.value
        @public_ip = instance.public_ip_address
        @availability_zone = instance.placement.availability_zone
        @launched_at = instance.launch_time
        @instance_type = instance.instance_type
      end

      def host
        @name
      end

      def terminate
        EC2.new.terminate_instance(@id)
      end

      def api_termination_disabled?
        @instance.describe_attribute(attribute: 'disableApiTermination').to_h[:disable_api_termination][:value]
      end

      class << self
        def retrieve(id)
          new(EC2.new.retrieve_instance(id))
        end

        def retrieve_by(id: nil, name: nil, name_regexp: nil)
          if id
            retrieve(id)
          elsif name
            new(EC2.new.retrieve_instance_by(name: name))
          elsif name_regexp
            instances = EC2.new.retrieve_instances.map do |instance|
              new(instance)
            end

            regexp = Regexp.new(name_regexp)
            instance = instances.select do |instance|
              instance.name && instance.name.match?(regexp) && !instance.api_termination_disabled?
            end.sort_by(&:launched_at)[0]

            unless instance
              raise "Instance not found regexp=#{regexp}"
            end

            instance
          else
            raise 'There are no search conditions'
          end
        end
      end
    end
  end
end
