module Taskbooks
  module AwsTask
    def build(params)
      if params['launch']
        if params['count'] && (count = params['count'].to_i) > 1
          EnumerableTask.new(count.times.map { LaunchTask.build(params) })
        else
          LaunchTask.build(params)
        end
      elsif params['terminate']
        if params['count'] && (count = params['count'].to_i) > 1
          EnumerableTask.new(count.times.map { TerminateTask.build(params) })
        else
          TerminateTask.build(params)
        end
      elsif params['sync']
        SyncTask.build(params)
      elsif params['list']
        ListTask.build(params)
      end
    end

    module_function :build
  end
end