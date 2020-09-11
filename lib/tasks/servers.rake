namespace :servers do
  desc 'Launch'
  task launch: :environment do |task|

    require_relative '../../deploy/bin/egotter'
    logger = Tasks::TaskBuilder.logger

    logger.info "#{task.name} started"

    params = {
        'adjust' => true,
        'role' => 'web',
        'count' => ENV['WEB_INSTANCES_MAX'] || 6
    }
    begin
      Tasks::TaskBuilder.build(params).run
      SlackClient.deploy.send_message("Succeeded task=#{task.name} params=#{params.inspect}") rescue nil
    rescue => e
      logger.warn "adjust task failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
      SlackClient.deploy.send_message("Failed task=#{task.name} params=#{params.inspect}") rescue nil
    end

    params = {
        'launch' => true,
        'role' => 'sidekiq_prompt_reports',
        'instance-type' => 'm5.xlarge'
    }
    begin
      Tasks::TaskBuilder.build(params).run
      SlackClient.deploy.send_message("Succeeded task=#{task.name} params=#{params.inspect}") rescue nil
    rescue => e
      logger.warn "launch task failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
      SlackClient.deploy.send_message("Failed task=#{task.name} params=#{params.inspect}") rescue nil
    end

    logger.info "#{task.name} finished"
  end

  desc 'Terminate'
  task terminate: :environment do |task|

    require_relative '../../deploy/bin/egotter'
    logger = Tasks::TaskBuilder.logger

    logger.info "#{task.name} started"

    params = {
        'adjust' => true,
        'role' => 'web',
        'count' => ENV['WEB_INSTANCES_MIN'] || 2
    }
    begin
      Tasks::TaskBuilder.build(params).run
      SlackClient.deploy.send_message("Succeeded task=#{task.name} params=#{params.inspect}") rescue nil
    rescue => e
      logger.warn "adjust task failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
      SlackClient.deploy.send_message("Failed task=#{task.name} params=#{params.inspect}") rescue nil
    end

    params = {
        'terminate' => true,
        'role' => 'sidekiq_prompt_reports',
        'instance-name-regexp' => 'egotter_sidekiq\\d{8}'
    }
    begin
      Tasks::TaskBuilder.build(params).run
      SlackClient.deploy.send_message("Succeeded task=#{task.name} params=#{params.inspect}") rescue nil
    rescue => e
      logger.warn "launch task failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
      SlackClient.deploy.send_message("Failed task=#{task.name} params=#{params.inspect}") rescue nil
    end

    logger.info "#{task.name} finished"
  end
end
