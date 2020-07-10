namespace :servers do
  desc 'Launch'
  task launch: :environment do |task|

    require_relative '../../deploy/bin/egotter'
    logger = Tasks::TaskBuilder.logger

    logger.info "#{task.name} started"

    begin
      params = {
          'adjust' => true,
          'role' => 'web',
          'count' => '4'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      logger.warn "adjust task failed params=#{params.inspect} exception=#{e.inspect}"
    end

    begin
      params = {
          'launch' => true,
          'role' => 'sidekiq_prompt_reports',
          'instance-type' => 'm5.xlarge'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      logger.warn "launch task failed params=#{params.inspect} exception=#{e.inspect}"
    end

    logger.info "#{task.name} finished"
  end

  desc 'Terminate'
  task terminate: :environment do |task|

    require_relative '../../deploy/bin/egotter'
    logger = Tasks::TaskBuilder.logger

    logger.info "#{task.name} started"

    begin
      params = {
          'adjust' => true,
          'role' => 'web',
          'count' => '2'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      logger.warn "adjust task failed params=#{params.inspect} exception=#{e.inspect}"
    end

    begin
      params = {
          'terminate' => true,
          'role' => 'sidekiq_prompt_reports',
          'instance-name-regexp' => 'egotter_sidekiq\\d{8}'
      }
      Tasks::TaskBuilder.build(params).run
    rescue => e
      logger.warn "launch task failed params=#{params.inspect} exception=#{e.inspect}"
    end

    logger.info "#{task.name} finished"
  end
end
