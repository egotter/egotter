require_relative './ec2'

module Egotter
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
        ::Egotter::Aws::EC2.terminate_instance(@id)
      end

      class << self
        def retrieve(id)
          new(::Egotter::Aws::EC2.retrieve_instance(id))
        end

        def retrieve_by(id: nil, name: nil)
          if id
            retrieve(id)
          else
            new(::Egotter::Aws::EC2.retrieve_instance_by(name: name))
          end
        end
      end
    end
  end
end
