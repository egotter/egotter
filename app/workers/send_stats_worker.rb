require 'datadog/statsd'

class SendStatsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform
    statsd = Datadog::Statsd.new('localhost', 8125)

    [
      CreateTwitterUserWorker,
      CreateSignedInTwitterUserWorker,
      DelayedCreateTwitterUserWorker,
      ImportTwitterUserRelationsWorker,
      DelayedImportTwitterUserRelationsWorker
    ].each do |klass|
      name = klass.name
      queue = Sidekiq::Queue.new(name)
      statsd.gauge("sidekiq.queues.#{name}.size", queue.size)
      statsd.gauge("sidekiq.queues.#{name}.latency", queue.latency)
    end
  rescue => e
    logger.warn "#{e.class} #{e.name}"
  ensure
    SendStatsWorker.perform_in(1.minute.since)
  end
end
