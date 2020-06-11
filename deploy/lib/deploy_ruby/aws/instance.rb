require_relative './ec2'

module DeployRuby
  module Aws
    class Instance
      attr_reader :id, :name, :public_ip, :availability_zone, :launched_at

      def initialize(instance)
        @id = instance.id
        @name = instance.tags.find { |t| t.key == 'Name' }&.value
        @public_ip = instance.public_ip_address
        @availability_zone = instance.placement.availability_zone
        @launched_at = instance.launch_time
      end

      def host
        @name
      end

      def terminate
        EC2.new.terminate_instance(@id)
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
            regexp = Regexp.new(name_regexp)
            found = EC2.new.retrieve_instances.find do |instance|
              name_tag = instance.tags.find { |t| t.key == 'Name' }.value
              regexp.match?(name_tag)
            end

            unless found
              raise "Instance not found regexp=#{regexp}"
            end

            new(found)
          else
            raise 'There are no search conditions'
          end
        end
      end
    end
  end
end
