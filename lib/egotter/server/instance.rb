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

      class << self
        def retrieve(id)
          instance = nil
          filters = [name: 'instance-id', values: [id]]
          ec2 = Aws::EC2::Resource.new(region: 'ap-northeast-1')
          ec2.instances(filters: filters).each do |i|
            instance = i
            break
          end
          instance ? new(instance) : nil
        end
      end
    end
  end
end