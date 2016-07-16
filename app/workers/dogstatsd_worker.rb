require 'statsd'

class DogstatsdWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform
    statsd = Statsd.new('localhost', 8125)
    table_stats(statsd)
    sidekiq_stats(statsd)
    redis_sats(statsd)

    DogstatsdWorker.perform_in(5.minutes) if Rails.env.production?
  end

  def table_stats(statsd)
    [User, Notification, TwitterUser].each do |model|
      statsd.gauge("egotter.#{model.table_name}.count", model.all.size)
    end
  rescue => e
    logger.warn "#{e}: #{e.message}"
  end

  def sidekiq_stats(statsd)
    queue = Sidekiq::Queue.new('egotter')
    statsd.gauge('egotter.sidekiq.job.count', queue.size)
    statsd.histogram('egotter.sidekiq.job.latency', queue.latency)

    statsd.gauge('egotter.sidekiq.process.count', Sidekiq::ProcessSet.new.size)
    statsd.gauge('egotter.sidekiq.worker.count', Sidekiq::Workers.new.size)

    stats = Sidekiq::Stats.new
    %i(processed failed enqueued).each do |name|
      statsd.gauge("egotter.sidekiq.stats.#{name}", stats.send(name))
    end
    statsd.gauge('egotter.sidekiq.stats.queues', stats.queues['egotter'])
  rescue => e
    logger.warn "#{e}: #{e.message}"
  end

  def redis_sats(statsd)
    redis = Redis.client
    statsd.gauge('egotter.list.searched', SearchedUidList.new(redis).size)
    statsd.gauge('egotter.list.unauthorized', UnauthorizedUidList.new(redis).size)
    statsd.gauge('egotter.list.too_many_friends', TooManyFriendsUidList.new(redis).size)
  rescue => e
    logger.warn "#{e}: #{e.message}"
  end
end
