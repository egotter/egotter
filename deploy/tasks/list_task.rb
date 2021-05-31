module Tasks
  module ListTask
    def build(params)
      role = params['role']

      case role
      when 'web'
        Web.new(params)
      when 'sidekiq'
        Sidekiq.new(params)
      when 'plain'
        Plain.new(params)
      else
        raise "Invalid role #{role}"
      end
    end

    module_function :build

    class Base
      attr_reader :action

      def initialize(params)
        @params = params
        @action = :list
        @instance_type = params['instance-type']
        @delim = params['delim'] || ' '
      end

      def run
        puts instance_names.join(@delim)
      end

      def instance_names
        fetch_instances.map(&:name)
      end

      private

      def fetch_instances
        ::Deploy::Aws::EC2.new.retrieve_instances(instance_type: @instance_type).map do |i|
          ::Deploy::Aws::Instance.new(i)
        end.select do |i|
          i.name&.match?(name_regexp)
        end.sort_by(&:name)
      end

      def logger
        Deploy.logger
      end
    end

    class Web < Base
      def fetch_instances
        state = @params['state'].to_s.empty? ? 'healthy' : @params['state']
        group = ::Deploy::Aws::TargetGroup.new(@params['target-group'])
        group.registered_instances(state: state, instance_type: @instance_type).sort_by(&:name)
      end
    end

    class Sidekiq < Base
      def name_regexp
        /^egotter_sidekiq[^5]/
      end
    end

    class Plain < Base
      def name_regexp
        /^egotter_plain/
      end
    end
  end
end
