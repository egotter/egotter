namespace :servers do
  desc 'Launch'
  task launch: :environment do

    require_relative '../../deploy/bin/egotter'

    begin
      params = {
          'adjust' => true,
          'role' => 'web',
          'count' => '4'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      puts "adjust task failed params=#{params.inspect} exception=#{e.inspect}"
    end

    begin
      params = {
          'launch' => true,
          'role' => 'sidekiq_prompt_reports',
          'instance-type' => 'm5.xlarge'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      puts "launch task failed params=#{params.inspect} exception=#{e.inspect}"
    end

  end

  desc 'Terminate'
  task terminate: :environment do

    require_relative '../../deploy/bin/egotter'

    begin
      params = {
          'adjust' => true,
          'role' => 'web',
          'count' => '2'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      puts "adjust task failed params=#{params.inspect} exception=#{e.inspect}"
    end

    begin
      params = {
          'terminate' => true,
          'role' => 'sidekiq_prompt_reports',
          'instance-name-regexp' => 'egotter_sidekiq\\d{8}'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      puts "launch task failed params=#{params.inspect} exception=#{e.inspect}"
    end

  end
end
