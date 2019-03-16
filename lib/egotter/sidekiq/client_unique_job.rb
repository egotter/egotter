module Egotter
  module Sidekiq
    class ClientUniqueJob
      include UniqueJobUtil

      def initialize(queue_class)
        @queue_class = queue_class
      end

      def call(worker_class, job, queue, redis_pool, &block)
        if job.has_key?('at')
          yield
        else
          worker_class = worker_class.constantize
          perform(worker_class.new, job['args'], @queue_class, &block)
        end
      end
    end
  end
end
