require_relative './enumerable_task'
require_relative './release_task'
require_relative './launch_task'
require_relative './terminate_task'
require_relative './sync_task'
require_relative './list_task'

module Tasks
  module TaskBuilder
    module_function

    def build(params)
      case
      when params['release']
        build_release_task(params)
      when params['launch']
        build_launch_task(params)
      when params['adjust']
        build_adjust_task(params)
      when params['terminate']
        build_terminate_task(params)
      when params['sync']
        build_sync_task(params)
      when params['list']
        build_list_task(params)
      else
        raise "Invalid action params=#{params.inspect}"
      end
    end

    def build_release_task(params)
      role = params['role']
      hosts = params['hosts'].split(',')

      if role == 'web'
        if hosts.size > 1
          Tasks::EnumerableTask.new(hosts.map { |host| Tasks::ReleaseWebTask.new(host) })
        else
          Tasks::ReleaseWebTask.new(hosts[0])
        end
      elsif role == 'sidekiq'
        if hosts.size > 1
          Tasks::EnumerableTask.new(hosts.map { |host| Tasks::ReleaseSidekiqTask.new(host) })
        else
          Tasks::ReleaseSidekiqTask.new(hosts[0])
        end
      else
        raise "Invalid role params=#{params.inspect}"
      end
    end

    def build_launch_task(params)
      if multiple_task?(params)
        count = params['count'].to_i
        tasks = count.times.map { Tasks::LaunchTask.build(params) }

        logger.info "Launch #{count} instances in parallel"

        tasks.map.with_index do |task, i|
          Thread.new { task.launch_instance(i) }
        end.each(&:join)

        Tasks::EnumerableTask.new(tasks)
      else
        Tasks::LaunchTask.build(params)
      end
    end

    def build_adjust_task(params)
      count = params['count'].to_i
      current_count = ::DeployRuby::Aws::TargetGroup.new(params['target-group']).registered_instances.size

      if count > current_count
        params['count'] = count - current_count
        logger.info "Launch #{params['count']} #{params['role']} instances"
        build_launch_task(params)

      elsif count < current_count
        params['count'] = current_count - count
        logger.info "Terminate #{params['count']} #{params['role']} instances"
        build_terminate_task(params)

      else
        raise "Already adjusted params=#{params.inspect}"
      end
    end

    def build_terminate_task(params)
      if multiple_task?(params)
        Tasks::EnumerableTask.new(params['count'].to_i.times.map { Tasks::TerminateTask.build(params) })
      else
        Tasks::TerminateTask.build(params)
      end
    end

    def build_sync_task(params)
      Tasks::SyncTask.build(params)
    end

    def build_list_task(params)
      Tasks::ListTask.build(params)
    end

    def multiple_task?(params)
      params['count'] && params['count'].to_i > 1
    end

    def logger
      DeployRuby.logger
    end
  end
end
