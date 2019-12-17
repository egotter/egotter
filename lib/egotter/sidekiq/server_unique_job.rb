module Egotter
  module Sidekiq
    class ServerUniqueJob
      include UniqueJobUtil

      def initialize(process_context = nil)
        @queue_class = Egotter::Sidekiq::RunHistory
        @queueing_context = 'server'
        @process_context = process_context || 'unspecified'
      end

      def call(worker, msg, queue, &block)
        history = run_history(worker, @queue_class, @queueing_context)
        perform(worker, msg['args'], history, &block)
      end
    end
  end
end
