module AwsTask
  def build(params)
    if params['launch']
      if params['count'] && (count = params['count'].to_i) > 1
        EnumerableTask.new(count.times.map { LaunchTask.build(params) })
      else
        LaunchTask.build(params)
      end
    elsif params['terminate']
      TerminateTask.build(params)
    elsif params['sync']
      SyncTask.build(params)
    elsif params['list']
      ListTask.build(params)
    end
  end

  module_function :build
end
