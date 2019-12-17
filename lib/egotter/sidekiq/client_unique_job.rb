module Egotter
  module Sidekiq
    class ClientUniqueJob
      include UniqueJobUtil

      def initialize(process_context = nil)
        @queue_class = Egotter::Sidekiq::RunHistory
        @queueing_context = 'client'
        @process_context = process_context || 'unspecified'
      end

      def call(worker_str, job, queue, redis_pool, &block)
        if job.has_key?('at')
          yield
        else
          worker = worker_str.constantize.new
          history = run_history(worker, @queue_class, @queueing_context)
          perform(worker, job['args'], history, &block)
        end
      end
    end
  end
end
