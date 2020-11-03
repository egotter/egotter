require_relative './enumerable_task'
require_relative './release_task'
require_relative './launch_task'
require_relative './terminate_task'
require_relative './sync_task'
require_relative './list_task'

module Tasks
  class TaskBuilder
    class << self
      def build(params)
        instance = new(params.dup)

        case
        when params['release']
          instance.release_task
        when params['launch']
          instance.launch_task
        when params['adjust']
          instance.adjust_task
        when params['terminate']
          instance.terminate_task
        when params['sync']
          instance.sync_task
        when params['list']
          instance.list_task
        else
          raise UnknownActionError, "params=#{params.inspect}"
        end
      end
    end

    class UnknownActionError < RuntimeError; end

    class UnknownRoleError < RuntimeError; end

    def initialize(params)
      @params = params
    end

    # Install latest applications on a server that is already running
    def release_task
      role = @params['role']
      hosts = @params['hosts'].split(',')

      if role == 'web'
        if hosts.size > 1
          Tasks::EnumerableTask.new(hosts.map { |host| Tasks::ReleaseTask::Web.new(host) })
        else
          Tasks::ReleaseTask::Web.new(hosts[0])
        end
      elsif role == 'sidekiq'
        if hosts.size > 1
          Tasks::EnumerableTask.new(hosts.map { |host| Tasks::ReleaseTask::Sidekiq.new(host) })
        else
          Tasks::ReleaseTask::Sidekiq.new(hosts[0])
        end
      else
        raise UnknownRoleError, "params=#{@params.inspect}"
      end
    end

    def launch_task
      if multiple_task?
        tasks = tasks_count.times.map { Tasks::LaunchTask.build(@params) }

        logger.info "Launch #{tasks_count} instances in parallel"

        tasks.map.with_index do |task, i|
          Thread.new { task.launch_instance(i) }
        end.each(&:join)

        Tasks::EnumerableTask.new(tasks)
      else
        Tasks::LaunchTask.build(@params)
      end
    end

    def adjust_task
      current_count = ::DeployRuby::Aws::TargetGroup.new(@params['target-group']).registered_instances.size

      if tasks_count > current_count
        @params['count'] = tasks_count - current_count
        logger.info "Launch #{@params['count']} #{@params['role']} instances"
        launch_task

      elsif tasks_count < current_count
        @params['count'] = current_count - tasks_count
        logger.info "Terminate #{@params['count']} #{@params['role']} instances"
        terminate_task

      else
        logger.info "Don't launch/terminate any instances"
      end
    end

    def terminate_task
      if multiple_task?
        Tasks::EnumerableTask.new(tasks_count.times.map { Tasks::TerminateTask.build(@params) })
      else
        Tasks::TerminateTask.build(@params)
      end
    end

    def sync_task
      Tasks::SyncTask.build(@params)
    end

    def list_task
      Tasks::ListTask.build(@params)
    end

    def multiple_task?
      @params['count'] && @params['count'].to_i > 1
    end

    def tasks_count
      @params['count'].to_i
    end

    def logger
      DeployRuby.logger
    end
  end
end
