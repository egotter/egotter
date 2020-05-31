module UniqueJob
  class ClientMiddleware
    include Util

    def call(worker_str, job, queue, redis_pool, &block)
      if job.has_key?('at')
        # perform_in or perform_at
        yield
      else
        if worker_str.class == String
          worker = worker_str.constantize.new # Sidekiq < 6
        else
          worker = worker_str.new
        end
        perform_if_unique(worker, job['args'], &block)
      end
    end
  end
end
