namespace :servers do
  desc 'Launch'
  task launch: :environment do |task|

    require_relative '../../deploy/bin/egotter'
    logger = SlackLogger.new(:deploy, DeployRuby.logger)

    logger.info "#{task.name} started"

    params = {
        'adjust' => true,
        'role' => 'web',
        'count' => ENV['WEB_INSTANCES_MAX'] || 2
    }
    begin
      Tasks::TaskBuilder.build(params).run
      logger.info "Succeeded task=#{task.name} params=#{params.inspect}"
    rescue => e
      logger.warn "Failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
    end

    params = {
        'adjust' => true,
        'role' => 'sidekiq',
        'count' => ENV['SIDEKIQ_INSTANCES_MAX'] || 4,
    }
    begin
      Tasks::TaskBuilder.build(params).run
      logger.info "Succeeded task=#{task.name} params=#{params.inspect}"
    rescue => e
      logger.warn "Failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
    end

    logger.info "#{task.name} finished"
  end

  desc 'Terminate'
  task terminate: :environment do |task|

    require_relative '../../deploy/bin/egotter'
    logger = SlackLogger.new(:deploy, DeployRuby.logger)

    logger.info "#{task.name} started"

    params = {
        'adjust' => true,
        'role' => 'web',
        'count' => ENV['WEB_INSTANCES_MIN'] || 2
    }
    begin
      Tasks::TaskBuilder.build(params).run
      logger.info "Succeeded task=#{task.name} params=#{params.inspect}"
    rescue => e
      logger.warn "Failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
    end

    params = {
        'adjust' => true,
        'role' => 'sidekiq',
        'count' => ENV['SIDEKIQ_INSTANCES_MIN'] || 0,
    }
    begin
      Tasks::TaskBuilder.build(params).run
      logger.info "Succeeded task=#{task.name} params=#{params.inspect}"
    rescue => e
      logger.warn "Failed task=#{task.name} params=#{params.inspect} exception=#{e.inspect}"
    end

    logger.info "#{task.name} finished"
  end
end
