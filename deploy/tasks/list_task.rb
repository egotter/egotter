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
        @action = :list
        @delim = params['delim'] || ' '
      end

      def run
        puts instance_names.join(@delim)
      end

      def logger
        Deploy.logger
      end
    end

    class Web < Base
      def initialize(params)
        super
        @state = params['state'].to_s.empty? ? 'healthy' : params['state']
        @target_group = ::Deploy::Aws::TargetGroup.new(params['target-group'])
      end

      def instance_names
        @target_group.registered_instances(state: @state).map(&:name).sort
      end
    end

    class Sidekiq < Base
      def initialize(params)
        super
      end

      def instance_names
        ::Deploy::Aws::EC2.new.retrieve_instances.map do |i|
          ::Deploy::Aws::Instance.new(i)
        end.select do |i|
          i.name&.match?(/^egotter_sidekiq[^5]/)
        end.map(&:name).sort
      end
    end

    class Plain < Base
      def initialize(params)
        super
      end

      def instance_names
        ::Deploy::Aws::EC2.new.retrieve_instances.map do |i|
          ::Deploy::Aws::Instance.new(i)
        end.select do |i|
          i.name&.start_with?('egotter_plain')
        end.map(&:name).sort
      end
    end
  end
end
