require_relative './ec2_util'
require_relative './instance'

module Egotter
  module Server
    module Launcher
      class Params
        def initialize(params)
          @values = {
              template: params['launch-template'] || ENV['AWS_LAUNCH_TEMPLATE'],
              security_group: params['security-group'] || ENV['AWS_SECURITY_GROUP'],
              subnet: pick_subnet(params),
          }

          if params['instance-type']
            @values[:instance_type] = params['instance-type']
          end
        end

        def pick_subnet(params)
          if params['availability-zone']
            az_to_subnet(params['availability-zone'])
          else
            ENV['AWS_SUBNET']
          end
        end

        def az_to_subnet(az)
          case az
          when 'ap-northeast-1b' then ENV['AWS_SUBNET_1B']
          when 'ap-northeast-1c' then ENV['AWS_SUBNET_1C']
          when 'ap-northeast-1d' then ENV['AWS_SUBNET_1D']
          end
        end

        def to_h
          @values
        end

        def to_s
          @values.inspect
        end
      end

      class Base
        def initialize(params)
          @params = params.to_h
        end

        def name
          raise NotImplementedError
        end

        def launch
          id = ::Egotter::Server::Ec2Util.launch_instance(@params.merge(name: name))
          ::Egotter::Server::Instance.retrieve(id)
        end
      end

      class Web < Base
        def name
          @name || "egotter_web#{Time.now.strftime('%m%d%H%M')}"
        end
      end

      class Sidekiq < Base
        def name
          @name ||= "egotter_sidekiq#{Time.now.strftime('%m%d%H%M')}"
        end
      end
    end
  end
end