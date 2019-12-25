module Egotter
  module Sidekiq
    module UniqueJobUtil
      include JobCallbackUtil

      def perform(worker, args, history, &block)
        if worker.respond_to?(:unique_key)
          if perform_unique_check(worker, args, history, worker.unique_key(*args))
            yield
          end
        else
          yield
        end
      end

      def perform_unique_check(worker, args, history, unique_key)
        if history.exists?(unique_key)
          worker.logger.info { "#{self.class}:#{worker.class} Skip duplicate job for #{history.ttl} seconds. #{args.inspect.truncate(100)}" }

          perform_callback(worker, :after_skip, args)

          false
        else
          history.add(unique_key)
          true
        end
      end

      def run_history(worker, queue_class, queueing_context)
        if worker.respond_to?(:unique_in)
          queue_class.new(worker.class, queueing_context, worker.unique_in)
        else
          queue_class.new(worker.class, queueing_context, 1.hour)
        end
      end
    end
  end
end
