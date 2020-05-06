module Egotter
  module Sidekiq
    class ClientUniqueJob
      include UniqueJobUtil

      def initialize(process_context = nil)
        @queue_class = ::Egotter::Sidekiq::RunHistory
        @queueing_context = 'client'
        @process_context = process_context || 'unspecified'
      end

      def call(worker_str, job, queue, redis_pool, &block)
        if job.has_key?('at')
          yield
        else
          if worker_str.class == String
            worker = worker_str.constantize.new # Sidekiq < 6
          else
            worker = worker_str.new
          end
          history = run_history(worker, @queue_class, @queueing_context)
          perform_if_unique(worker, job['args'], history, &block)
        end
      end
    end
  end
end
