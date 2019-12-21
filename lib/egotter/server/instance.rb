require_relative './ec2_util'

module Egotter
  module Server
    class Instance
      attr_reader :id, :name, :public_ip, :availability_zone, :launched_at

      def initialize(instance)
        @id = instance.id
        @name = instance.tags.find { |t| t.key == 'Name' }&.value
        @public_ip = instance.public_ip_address
        @availability_zone = instance.placement.availability_zone
        @launched_at = instance.launch_time
      end

      def terminate
        ::Egotter::Server::Ec2Util.terminate_instance(@id)
      end

      class << self
        def retrieve(id)
          new(::Egotter::Server::Ec2Util.retrieve_instance(id))
        end
      end
    end
  end
end