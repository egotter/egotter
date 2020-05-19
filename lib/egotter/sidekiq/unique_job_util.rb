module Egotter
  module Sidekiq
    module UniqueJobUtil
      include JobCallbackUtil

      def perform_if_unique(worker, args, history, &block)
        if worker.respond_to?(:unique_key)
          start = Time.now

          unique_key = worker.unique_key(*args).to_s
          if unique_key.nil? || unique_key.empty?
            worker.logger.warn { "#{__method__} Key is blank worker=#{worker} args=#{args.inspect.truncate(100)}" }
          end

          result = perform_unique_check(worker, args, history, unique_key)
          worker.logger.debug { "#{__method__} elapsed=#{sprintf("%.3f sec", Time.now - start)} worker=#{worker} args=#{args.inspect.truncate(100)}" }

          if result
            yield
          end
        else
          yield
        end
      end

      def perform_unique_check(worker, args, history, unique_key)
        if history.exists?(unique_key)
          worker.logger.info { "#{__method__} Skip duplicate job for #{history.ttl} seconds, remaining #{history.ttl(unique_key)} seconds worker=#{worker} args=#{args.inspect.truncate(100)}" }

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
