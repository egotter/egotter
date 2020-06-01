namespace :servers do
  desc 'Launch'
  task launch: :environment do

    require_relative '../../deploy/bin/egotter'

    params = {
        'launch' => true,
        'role' => 'sidekiq_prompt_reports',
        'instance-type' => 'm5.xlarge'
    }

    task = Tasks::TaskBuilder.build(params)
    task.run
  end

  desc 'Terminate'
  task terminate: :environment do

    require_relative '../../deploy/bin/egotter'

    params = {
        'terminate' => true,
        'role' => 'sidekiq_prompt_reports',
        'instance-name-regexp' => 'egotter_sidekiq\\d{8}'
    }

    task = Tasks::TaskBuilder.build(params)
    task.run
  end
end
