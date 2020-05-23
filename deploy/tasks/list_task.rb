module Tasks
  module ListTask
    def build(params)
      role = params['role']

      case role
      when 'web'
        WebTask.new(params)
      when 'sidekiq'
        SidekiqTask.new(params)
      when 'plain'
        PlainTask.new(params)
      else
        raise "Invalid role #{role}"
      end
    end

    module_function :build

    class Task < ::DeployRuby::Task
      attr_reader :action

      def initialize
        @action = :list
      end
    end

    class WebTask < Task
      def initialize(params)
        @state = params['state'].to_s.empty? ? 'healthy' : params['state']
        @delim = params['delim'] || ' '

        @target_group = ::DeployRuby::Aws::TargetGroup.new(params['target-group'])
      end

      def run
        puts @target_group.registered_instances(state: @state).map(&:name).sort.join(@delim)
      end
    end

    class SidekiqTask < Task
      def initialize(params)
        @delim = params['delim'] || ' '
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

    class PlainTask < Task
      def initialize(params)
        @delim = params['delim'] || ' '
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
