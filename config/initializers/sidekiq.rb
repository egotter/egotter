Sidekiq::Logging.logger.level = Logger::DEBUG

class SidekiqServerUniqueJob
  def initialize(queue_class)
    @queue_class = queue_class
  end

  def call(worker, msg, queue)
    worker_class = worker.class

    if worker.respond_to?(:unique_key)
      unique_queueing = @queue_class.new(worker_class)
      options = msg['args'].dup.extract_options!
      unique_key = worker.unique_key(*msg['args'])

      if !options['skip_unique'] && unique_queueing.exists?(unique_key)
        worker.logger.info "Server:#{worker_class} Skip duplicate job. #{options.inspect}"

        if worker.respond_to?(:after_skip)
          worker.after_skip(*msg['args'])
        end

        return false
      end
      unique_queueing.add(unique_key)
    end

    yield
  end
end

class SidekiqClientUniqueJob
  def initialize(queue_class)
    @queue_class = queue_class
  end

  def call(worker_class, job, queue, redis_pool)
    worker_class = worker_class.constantize
    worker_instance = worker_class.new

    if worker_instance.respond_to?(:unique_key)
      unique_queueing = @queue_class.new(worker_class)
      options = job['args'].dup.extract_options!
      unique_key = worker_instance.unique_key(*job['args'])

      if !options['skip_unique'] && unique_queueing.exists?(unique_key)
        worker_instance.logger.info "Client:#{worker_class} Skip duplicate job. #{options.inspect}"

        if worker_instance.respond_to?(:after_skip)
          worker_instance.after_skip(*msg['args'])
        end

        return false
      end
      unique_queueing.add(unique_key)
    end

    yield
  end
end

class SidekiqTimeoutJob
  def call(worker, msg, queue)
    if worker.respond_to?(:timeout_in)
      begin
        Timeout.timeout(worker.timeout_in) do
          yield
        end
      rescue Timeout::Error => e
        worker.logger.warn "#{e.class}: #{e.message} #{worker.timeout_in} #{msg['args']}"
        worker.logger.info e.backtrace.join("\n")

        if worker.respond_to?(:retry_in)
          worker.class.perform_in(worker.retry_in, *msg['args'])
        end
      end
    else
      yield
    end
  end
end

class SidekiqExpireJob
  def call(worker, msg, queue)
    if worker.respond_to?(:expire_in)
      options = msg['args'].dup.extract_options!

      if options['enqueued_at'].blank?
        worker.logger.warn {"enqueued_at not found. #{options.inspect}"}
      else
        if Time.zone.parse(options['enqueued_at']) < Time.zone.now - worker.expire_in
          worker.logger.info {"Skip expired job. #{options.inspect}"}
          return false
        end
      end
    end
    yield
  end
end

Sidekiq.configure_server do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379"}
  config.server_middleware do |chain|
    chain.add SidekiqServerUniqueJob, RunningQueue
    chain.add SidekiqExpireJob
    chain.add SidekiqTimeoutJob
  end
  config.client_middleware do |chain|
    chain.add SidekiqClientUniqueJob, QueueingRequests
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: "redis://#{ENV['REDIS_HOST']}:6379"}
  config.client_middleware do |chain|
    chain.add SidekiqClientUniqueJob, QueueingRequests
  end
end