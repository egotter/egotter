Sidekiq::Logging.logger.level = Logger::DEBUG

module UniqueJobUtil
  module_function

  def perform(worker, args, queue, &block)
    if worker.respond_to?(:unique_key)
      options = args.dup.extract_options!
      unique_key = worker.unique_key(*args)

      if !options['skip_unique'] && queue.exists?(unique_key)
        worker.logger.info "Server:#{worker.class} Skip duplicate job. #{args.inspect.truncate(100)}"

        if worker.respond_to?(:after_skip)
          worker.after_skip(*args)
        end

        return false
      end

      queue.add(unique_key)
    end

    yield
  end
end

class SidekiqServerUniqueJob
  def initialize(queue_class)
    @queue_class = queue_class
  end

  def call(worker, msg, queue, &block)
    UniqueJobUtil.perform(worker, msg['args'], @queue_class.new(worker.class), &block)
  end
end

class SidekiqClientUniqueJob
  def initialize(queue_class)
    @queue_class = queue_class
  end

  def call(worker_class, job, queue, redis_pool, &block)
    worker_class = worker_class.constantize
    UniqueJobUtil.perform(worker_class.new, job['args'], @queue_class.new(worker_class), &block)
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

        if worker.respond_to?(:after_timeout)
          worker.after_timeout(*msg['args'])
        end

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