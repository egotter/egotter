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

      def logger
        DeployRuby.logger
      end
    end

    class Web < Base
      def initialize(params)
        super
        @state = params['state'].to_s.empty? ? 'healthy' : params['state']
        @target_group = ::DeployRuby::Aws::TargetGroup.new(params['target-group'])
      end

      def run
        puts @target_group.registered_instances(state: @state).map(&:name).sort.join(@delim)
      end
    end

    class Sidekiq < Base
      def initialize(params)
        super
      end

      def run
        instances =
            ::DeployRuby::Aws::EC2.new.retrieve_instances.map do |i|
              ::DeployRuby::Aws::Instance.new(i)
            end.select do |i|
              i.name&.start_with?('egotter_sidekiq')
            end
        puts instances.map(&:name).join(@delim)
      end
    end

    class Plain < Base
      def initialize(params)
        super
      end

      def run
        instances =
            ::DeployRuby::Aws::EC2.new.retrieve_instances.map do |i|
              ::DeployRuby::Aws::Instance.new(i)
            end.select do |i|
              i.name&.start_with?('egotter_plain')
            end
        puts instances.map(&:name).join(@delim)
      end
    end
  end
end
