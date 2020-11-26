namespace :servers do
  desc 'Launch'
  task launch: :environment do |task|

    require_relative '../../bin/deploy'
    logger = SlackLogger.new(:deploy, Deploy.logger)

    logger.info "#{task.name} started"

    params = {
        'adjust' => true,
        'role' => 'web',
        'instance-type' => 't3.medium',
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
        'instance-type' => 'm5.large',
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

    require_relative '../../bin/deploy'
    logger = SlackLogger.new(:deploy, Deploy.logger)

    logger.info "#{task.name} started"

    params = {
        'adjust' => true,
        'role' => 'web',
        'instance-type' => 't3.medium',
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
        'instance-type' => 'm5.large',
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
